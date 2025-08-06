module ApplicationHelper
  def active_class(current_controller)
    current_controller == controller_path ? "active" : ""
  end

  def active_flag(current_controller)
    current_controller == controller_path ? true : false
  end
end
