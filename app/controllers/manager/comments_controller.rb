class Manager::CommentsController < BaseController
  include ActionView::Helpers::DateHelper

  before_action :require_manager
  before_action :set_daily_report
  before_action :authorize_company

  def create
    @comment = @daily_report.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      render json: {
        status: 'success',
        comment: serialize_comment(@comment),
        comments_count: @daily_report.comments.count
      }
    else
      render json: {
        status: 'error',
        errors: @comment.errors.full_messages
      }, status: 422
    end
  end

  def destroy
    @comment = @daily_report.comments.find(params[:id])
    
    unless @comment.user_id == current_user.id
      render json: { status: 'error', message: '削除権限がありません' }, status: 403
      return
    end

    @comment.destroy
    render json: {
      status: 'success',
      comments_count: @daily_report.comments.count
    }
  end

  private

  def require_manager
    unless current_user&.is_manager?
      render json: { status: 'error', message: 'この機能を利用する権限がありません' }, status: 403
    end
  end

  def set_daily_report
    @daily_report = DailyReport.find(params[:daily_report_id])
  end

  def authorize_company
    unless @daily_report.user.company_id == current_user.company_id
      render json: { status: 'error', message: 'アクセス権限がありません' }, status: 403
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def serialize_comment(comment)
    {
      id: comment.id,
      content: comment.content,
      user_name: comment.user.name,
      user_avatar_url: comment.user.avatar.attached? ? url_for(comment.user.avatar_thumbnail) : nil,
      created_at: time_ago_in_words(comment.created_at) + '前',
      can_delete: comment.user_id == current_user.id
    }
  end
end