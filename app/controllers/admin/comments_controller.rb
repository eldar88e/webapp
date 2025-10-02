module Admin
  class CommentsController < ApplicationController
    before_action :set_task

    def create
      @comment = @task.comments.build(comment_params.merge(user: current_user))
      if @comment.save
        render turbo_stream: [
          turbo_stream.prepend(:comments, partial: '/admin/comments/comment', locals: { comment: @comment }),
          turbo_stream.replace('comments-form', partial: '/admin/comments/form'),
          success_notice('Комментарий успешно добавлен.')
        ]
      else
        error_notice @comment.errors.full_messages
      end
    end

    private

    def set_task
      @task = Task.find(params[:task_id])
    end

    def comment_params
      params.require(:comment).permit(:body)
    end
  end
end
