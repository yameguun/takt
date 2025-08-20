class HelloJob < ApplicationJob
  queue_as :default

  def perform(name = "World")
    Rails.logger.info "[HelloJob] Hello, #{name}! 処理開始"
    sleep 2  # 処理時間をシミュレート
    Rails.logger.info "[HelloJob] Hello, #{name}! 処理完了"
  end
end