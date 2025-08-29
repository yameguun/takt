# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  discarded_at    :datetime
#  email           :string(255)      not null
#  name            :string(255)
#  password_digest :string(255)
#  permission      :integer          default(0), not null
#  unit_price      :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  department_id   :integer
#
# Indexes
#
#  index_users_on_company_id    (company_id)
#  index_users_on_discarded_at  (discarded_at)
#  index_users_on_email         (email) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#

class User < ApplicationRecord
  include Discard::Model

  has_secure_password

  has_one_attached :avatar

  belongs_to :company
  belongs_to :department, optional: true

  has_one :authentication, dependent: :destroy
  has_many :daily_reports, dependent: :destroy
  has_many :comments, dependent: :destroy

  self.discard_column = :discarded_at

  # 権限レベルの定義
  PERMISSION_LEVELS = {
    0 => '一般ユーザー',
    1 => 'マネージャー',
    2 => '管理者',
    3 => 'システム管理者'
  }.freeze

  # マネージャー除外用スコープ
  scope :non_managers, -> { where(permission: 0) }

  validates :email, presence: true, uniqueness: true
  validate :email_or_alphanumeric_format
  validates :unit_price, presence: true, numericality: true
  validates :permission, inclusion: { in: PERMISSION_LEVELS.keys }
  validate :acceptable_image

  def is_manager?
    self.permission > 0
  end

  # 権限レベルの日本語名を取得
  def permission_name
    PERMISSION_LEVELS[self.permission] || '不明'
  end

  # セレクトボックス用のオプション配列を生成
  def self.permission_options
    PERMISSION_LEVELS.map { |value, label| [label, value] }
  end

   # サムネイル版（100x100以内にリサイズ）
  def avatar_thumbnail
    avatar.variant(
      resize_to_limit: [100, 100],
      format: :webp,  # WebP形式に変換（軽量化）
      saver: { quality: 80 }  # 品質80%
    ).processed
  end
  
  # 中サイズ版（300x300以内にリサイズ）
  def avatar_medium
    avatar.variant(
      resize_to_limit: [300, 300],
      format: :webp,
      saver: { quality: 85 }
    ).processed
  end

  private

  def acceptable_image
    return unless avatar.attached?
    
    unless avatar.blob.byte_size <= 5.megabyte
      errors.add(:avatar, "は5MB以下にしてください")
    end
    
    acceptable_types = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"]
    unless acceptable_types.include?(avatar.blob.content_type)
      errors.add(:avatar, "はJPEG、PNG、GIF、WebP形式でアップロードしてください")
    end
  end

  def email_or_alphanumeric_format
    # emailが存在する場合にのみチェックを行う
    # (presence: true が既にnilや空文字列をハンドルしているため)
    if email.present?
      # 標準のメールアドレス形式にマッチするか、または半角英数字のみの形式にマッチするか
      is_email_format = URI::MailTo::EMAIL_REGEXP.match?(email)
      is_alphanumeric_format = /\A[a-zA-Z0-9]+\z/.match?(email)

      # どちらの形式にもマッチしない場合にエラーを追加
      unless is_email_format || is_alphanumeric_format
        errors.add(:email, "は有効なメールアドレス形式、または半角英数字のみで入力してください")
      end
    end
  end
end
