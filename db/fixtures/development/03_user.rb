# 管理者データの作成
User.find_or_create_by!(email: 'ts@suncackikaku.co.jp') do |user|
  user.company = Company.all.first
  user.password = 'password'
  user.password_confirmation = 'password'
end