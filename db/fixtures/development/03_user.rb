# 管理者データの作成
User.find_or_create_by!(email: 'ts@suncackikaku.co.jp') do |user|
  user.company = Company.all.first
  user.department = Department.all.first
  user.password = 'password'
  user.password_confirmation = 'password'
  user.name = "三角太郎"
  user.permission = 1
end

User.find_or_create_by!(email: 'user1@suncackikaku.co.jp') do |user|
  user.company = Company.all.first
  user.department = Department.all.first
  user.password = 'password'
  user.password_confirmation = 'password'
  user.name = "三角テスト"
end