# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
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
#  index_users_on_company_id  (company_id)
#  index_users_on_email       (email) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#

class User < ApplicationRecord
  has_secure_password

  has_one_attached :avatar

  belongs_to :company
  belongs_to :department, optional: true

  has_one :authentication, dependent: :destroy
  
  has_many :daily_reports, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :unit_price, presence: true, numericality: true
  validate :acceptable_image

  def is_manager?
    self.permission > 0
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
end
