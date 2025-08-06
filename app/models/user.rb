# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  company_id      :integer          not null
#  email           :string(255)      not null
#  password_digest :string(255)
#  name            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_company_id  (company_id)
#  index_users_on_email       (email) UNIQUE
#

class User < ApplicationRecord
  has_one :authentication, dependent: :destroy

  validates :customer_code, uniqueness: true, allow_nil: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # コールバックの設定
  before_create :generate_customer_code

  def phone_number=(number)
    # numberがnilでなければ、gsubで数字以外の文字(\D)を全て除去する
    cleaned_number = number&.gsub(/\D/, '')
    # superで親クラスの同名メソッドを呼び出し、整形後の値をセットする
    super(cleaned_number)
  end

  def is_member?
    self.first_name.present? && self.last_name.present? && self.phone_number.present? && self.birthday.present?
  end

  private

  # numberを生成するメソッド
  def generate_customer_code
    # 他のレコードと重複しないユニークな値が見つかるまでループする
    loop do
      # 20桁のランダムな数字文字列を生成
      self.customer_code = SecureRandom.random_number(10**20).to_s.rjust(20, '0')
      # 生成した番号がデータベースに存在しないことを確認してループを抜ける
      break unless User.exists?(customer_code: self.customer_code)
    end
  end
end
