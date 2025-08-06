module ApplicationHelper
  def active_class(current_controller)
    current_controller == controller_path ? "active" : ""
  end

  def active_flag(current_controller)
    current_controller == controller_path ? true : false
  end

  # 動的タイトル取得
  def get_title(title_name)
    title = "Takt"
    if title_name.present?
      title = title_name + " | Takt"
    end
    return title
  end
end
