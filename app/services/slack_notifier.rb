# app/services/slack_notifier.rb
require 'net/http'
require 'uri'
require 'json'

class SlackNotifier
  # カスタム例外クラス（リトライ制御用）
  class DeliveryError < StandardError; end
  class ConfigurationError < StandardError; end

  class << self
    def send_message(text, channel: nil, username: nil, blocks: nil)
      
      payload = build_payload(text, channel, username, blocks)
      response = send_request(payload)
      
      handle_response(response, text)
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error, SocketError => e
      # ネットワーク系エラーはリトライ対象
      Rails.logger.warn "Slack network error: #{e.message}"
      raise DeliveryError, "Network error: #{e.message}"
    rescue JSON::GeneratorError => e
      # JSON生成エラーはリトライしない
      Rails.logger.error "Slack JSON error: #{e.message}"
      false
    end

    private

    def slack_config
      @slack_config ||= Rails.application.credentials.slack
    end

    def build_payload(text, channel, username, blocks)
      payload = {
        text: text,
        channel: channel ||  '#日報',
        username: username || 'TSUBASA'
      }
  
      payload[:blocks] = blocks if blocks.present?
      payload
    end

    def send_request(payload)
      uri = URI(ENV["SLACK_WEBHOOK_URL"])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
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
          Rails.logger.error "Slack unexpected response: #{response.body}"
          raise DeliveryError, "Unexpected response: #{response.body}"
        end
      when 429
        # レート制限
        retry_after = response['Retry-After']&.to_i || 60
        raise DeliveryError, "Rate limited, retry after #{retry_after}s"
      when 400..499
        # クライアントエラー（リトライしない）
        Rails.logger.error "Slack client error: #{response.code} #{response.body}"
        false
      when 500..599
        # サーバーエラー（リトライする）
        raise DeliveryError, "Server error: #{response.code} #{response.body}"
      else
        raise DeliveryError, "Unexpected status: #{response.code}"
      end
    end
  end
end