# app/jobs/high_priority_slack_job.rb
class HighPrioritySlackJob < SlackNotificationJob
  queue_as :default  # 高優先度キュー
  
  # より積極的なリトライ
  retry_on SlackNotifier::DeliveryError,
           wait: 2.seconds,
           attempts: 5,
           jitter: 0.1

  def perform(message, options = {})
    # 高優先度フラグを自動設定
    options[:critical] = true
    super(message, options)
  end
end
