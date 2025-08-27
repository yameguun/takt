require 'aws-sdk-s3'

namespace :backup do
  desc "バックアップ"
  task :execute => :environment do
    timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    backup_file = "#{Rails.root}/tmp/backups/#{timestamp}_dump.sql.gz"
    `mkdir -p tmp/backups`
    `mysqldump --skip-column-statistics -u root -p --default-character-set=binary takt_production --password=#{ENV["MYAPP_DATABASE_PASSWORD"]} | gzip -c > #{backup_file}`
    send_to_s3_nightly(backup_file)
  end

  def send_to_s3_nightly(file_path)
    s3 = get_bucket
    file_name = File.basename(file_path)
    s3.put_object(
      bucket: "#{ENV['AWS_FOG_DIRECTORY']}",
      key: "backup/#{file_name}",
      body: File.open("#{file_path}")
    )
  end

  def get_bucket
    s3 = Aws::S3::Client.new(
      region: 'ap-northeast-1',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end
end
