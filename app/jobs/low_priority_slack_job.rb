# app/jobs/low_priority_slack_job.rb
class LowPrioritySlackJob < SlackNotificationJob
  queue_as :low_priority
  
  # 失敗を許容する設定
  retry_on SlackNotifier::DeliveryError, attempts: 1
  
  def perform(message, options = {})
    # 低優先度は失敗時の代替処理なし
    options[:critical] = false
    super(message, options)
  end
end