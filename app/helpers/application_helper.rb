module ApplicationHelper
  def active_class(current_controller)
    current_controller == controller_path ? "active" : ""
  end

  def active_flag(current_controller)
    current_controller == controller_path ? true : false
  end

  # 動的タイトル取得
  def get_title(title_name)
    title = "TSUBASA"
    if title_name.present?
      title = title_name + " | TSUBASA"
    end
    return title
  end

  def user_avatar_tag(user, options = {})
    default_options = {
      class: "img-circle",
      style: "width: 32px; height: 32px;",
      alt: user.name
    }
    
    options = default_options.merge(options)
    
    if user.avatar.attached?
      image_tag(user.avatar, options)
    else
      # デフォルト画像またはイニシャル画像を表示
      image_tag("https://placehold.jp/a6a6a6/ffffff/200x200.png?text=#{user.name.first.upcase}", options)
    end
  end
end
