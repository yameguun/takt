# 管理者データの作成
Administrator.find_or_create_by!(email: 'admin@suncackikaku.co.jp') do |admin|
  admin.password = 'Kj%$USQgAEj6'
  admin.password_confirmation = 'Kj%$USQgAEj6'
end