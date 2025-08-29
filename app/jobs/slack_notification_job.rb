# app/jobs/slack_notification_job.rb
class SlackNotificationJob < ApplicationJob
  queue_as :slack_notifications
  
  # Solid Queue対応のリトライ設定
  retry_on SlackNotifier::DeliveryError,
           wait: :exponentially_longer,
           attempts: 3,
           jitter: 0.15
  
  # 設定エラーはリトライしない
  discard_on SlackNotifier::ConfigurationError
  discard_on ActiveJob::DeserializationError

  def perform(message, options = {})
    job_start_time = Time.current
    
    Rails.logger.info "SlackNotificationJob started: queue=#{queue_name}, job_id=#{job_id}"
    
    result = SlackNotifier.send_message(
      message,
      channel: options[:channel],
      username: options[:username],
      blocks: options[:blocks]
    )
    
    execution_time = Time.current - job_start_time
    
    if result
      Rails.logger.info "SlackNotificationJob completed: duration=#{execution_time.round(3)}s"
    else
      Rails.logger.warn "SlackNotificationJob failed (non-retryable): duration=#{execution_time.round(3)}s"
      handle_notification_failure(message, options)
    end
    
    result
  end

  private

  def handle_notification_failure(message, options)
    # 重要な通知の場合は代替手段を実行
    if options[:critical] == true
      AdminNotificationMailer.slack_failure(
        message: message,
        options: options,
        job_id: job_id,
        failed_at: Time.current
      ).deliver_now
    end
    
    # メトリクス収集（将来的な監視のため）
    Rails.logger.error "Critical Slack notification failed: #{message.truncate(100)}"
  end
end