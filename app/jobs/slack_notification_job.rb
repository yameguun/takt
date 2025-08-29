# app/jobs/slack_notification_job.rb
class SlackNotificationJob < ApplicationJob
  queue_as :slack_notifications
  
  retry_on SlackNotifier::RateLimitError, wait: ->(executions) do
    error = executions.last.error
    error.respond_to?(:retry_after) ? error.retry_after.seconds : 60.seconds
  end, attempts: 2
  
  retry_on SlackNotifier::DeliveryError,
           wait: :exponentially_longer,
           attempts: 3,
           jitter: 0.15
  
  discard_on SlackNotifier::ConfigurationError do |job, error|
    Rails.logger.error "Slack configuration error (job discarded): #{error.message}"
    job.handle_configuration_error(error)
  end
  
  discard_on ActiveJob::DeserializationError

  def perform(message, options = {})
    job_start_time = Time.current
    attempt_number = executions
    
    Rails.logger.info "SlackNotificationJob started: queue=#{queue_name}, job_id=#{job_id}, attempt=#{attempt_number}"
    
    result = SlackNotifier.send_message(
      message,
      channel: options[:channel],
      username: options[:username],
      blocks: options[:blocks],
      webhook_url: options[:webhook_url]
    )
    
    execution_time = Time.current - job_start_time
    
    if result
      Rails.logger.info "SlackNotificationJob completed: duration=#{execution_time.round(3)}s, attempt=#{attempt_number}"
      track_success_metrics(execution_time, attempt_number)
    else
      Rails.logger.warn "SlackNotificationJob failed (non-retryable): duration=#{execution_time.round(3)}s"
      handle_notification_failure(message, options)
    end
    
    result
  end

  private

  def handle_notification_failure(message, options)
    if options[:critical] == true
      AdminNotificationMailer.slack_failure(
        message: message,
        options: options,
        job_id: job_id,
        failed_at: Time.current,
        attempt_number: executions
      ).deliver_now
    end
    
    track_failure_metrics(options[:critical])
    
    Rails.logger.error "Slack notification failed: critical=#{options[:critical]}, message=#{message.truncate(100)}"
  end

  def handle_configuration_error(error)
    AdminNotificationMailer.slack_configuration_error(
      error_message: error.message,
      job_id: job_id,
      occurred_at: Time.current
    ).deliver_now if defined?(AdminNotificationMailer)
  end

  def track_success_metrics(execution_time, attempt_number)
    return unless defined?(Rails.application.metrics)
    
    Rails.application.metrics.increment('slack_notifications.success')
    Rails.application.metrics.timing('slack_notifications.execution_time', execution_time * 1000)
    Rails.application.metrics.gauge('slack_notifications.attempts', attempt_number)
  end

  def track_failure_metrics(is_critical)
    return unless defined?(Rails.application.metrics)
    
    Rails.application.metrics.increment('slack_notifications.failure')
    Rails.application.metrics.increment('slack_notifications.critical_failure') if is_critical
  end
end