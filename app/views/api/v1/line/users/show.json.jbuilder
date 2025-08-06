json.user do
  json.id @user.id
  json.customer_code @user.customer_code
  json.first_name @user.first_name
  json.last_name @user.last_name
  json.phone_number @user.phone_number
  json.birthday @user.birthday
  json.is_member @user.is_member?
  json.point @user.point
  json.point_expire_date @user.point_expire_date
end