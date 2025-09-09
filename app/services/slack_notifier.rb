# app/services/slack_notifier.rb
require 'net/http'
require 'uri'
require 'json'

class SlackNotifier
  class DeliveryError < StandardError; end
  class ConfigurationError < StandardError; end
  class RateLimitError < DeliveryError
    attr_reader :retry_after
    
    def initialize(message, retry_after: 60)
      super(message)
      @retry_after = retry_after
    end
  end

  class << self
    def send_message(text, channel: nil, username: nil, blocks: nil, webhook_url: nil)
      validate_configuration!(webhook_url)
      
      payload = build_payload(text, channel, username, blocks)
      response = send_request(payload, webhook_url)
      
      handle_response(response, text)
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error, SocketError => e
      Rails.logger.warn "Slack network error: #{e.message}"
      raise DeliveryError, "Network error: #{e.message}"
    rescue JSON::GeneratorError => e
      Rails.logger.error "Slack JSON error: #{e.message}"
      false
    rescue StandardError => e
      Rails.logger.error "Unexpected Slack error: #{e.class} - #{e.message}"
      raise DeliveryError, "Unexpected error: #{e.message}"
    end

    private

    def validate_configuration!(custom_webhook_url)
      webhook_url = custom_webhook_url || default_webhook_url
      raise ConfigurationError, "Slack webhook URL not configured" if webhook_url.blank?
      
      uri = URI.parse(webhook_url)
      raise ConfigurationError, "Invalid webhook URL format" unless uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError => e
      raise ConfigurationError, "Invalid webhook URL: #{e.message}"
    end

    def default_webhook_url
      ENV["SLACK_WEBHOOK_URL"] || Rails.application.credentials.dig(:slack, :webhook_url)
    end

    def default_channel
      ENV["SLACK_DEFAULT_CHANNEL"] || Rails.application.credentials.dig(:slack, :default_channel) || '#日報'
    end

    def default_username
      ENV["SLACK_DEFAULT_USERNAME"] || Rails.application.credentials.dig(:slack, :default_username) || 'TSUBASA'
    end

    def build_payload(text, channel, username, blocks)
      payload = {
        text: sanitize_text(text),
        channel: channel || default_channel,
        username: username || default_username
      }
  
      payload[:blocks] = blocks if blocks.present?
      payload
    end

    def sanitize_text(text)
      return "" if text.nil?
      text.to_s.strip.truncate(80000)
    end

    def send_request(payload, custom_webhook_url)
      webhook_url = custom_webhook_url || default_webhook_url
      uri = URI(webhook_url)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.max_retries = 0

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['User-Agent'] = "RailsSlackNotifier/1.0"
      request.body = JSON.generate(payload)
      
      http.request(request)
    end

    def handle_response(response, original_text)
      case response.code.to_i
      when 200
        if response.body.strip == 'ok'
          Rails.logger.info "Slack notification sent successfully: #{original_text.truncate(50)}"
          true
        else
          Rails.logger.error "Slack unexpected response body: #{response.body}"
          raise DeliveryError, "Unexpected response: #{response.body}"
        end
      when 429
        retry_after = response['Retry-After']&.to_i || 60
        Rails.logger.warn "Slack rate limited, retry after #{retry_after}s"
        raise RateLimitError.new("Rate limited", retry_after: retry_after)
      when 400
        Rails.logger.error "Slack bad request: #{response.body}"
        false
      when 401, 403, 404
        Rails.logger.error "Slack configuration error: #{response.code} #{response.body}"
        raise ConfigurationError, "Invalid webhook configuration: #{response.code}"
      when 410
        Rails.logger.error "Slack webhook deprecated: #{response.body}"
        raise ConfigurationError, "Webhook URL is deprecated"
      when 402, 405..499
        Rails.logger.error "Slack client error: #{response.code} #{response.body}"
        false
      when 500..599
        Rails.logger.error "Slack server error: #{response.code} #{response.body}"
        raise DeliveryError, "Server error: #{response.code}"
      else
        Rails.logger.error "Slack unexpected status: #{response.code} #{response.body}"
        raise DeliveryError, "Unexpected status: #{response.code}"
      end
    end
  end
end