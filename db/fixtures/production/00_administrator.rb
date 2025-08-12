# 管理者データの作成
Administrator.find_or_create_by!(email: 'admin@suncackikaku.co.jp') do |admin|
  admin.password = 'password'
  admin.password_confirmation = 'password'
end