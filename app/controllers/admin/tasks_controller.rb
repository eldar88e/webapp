module Admin
  class TasksController < ApplicationController
    before_action :set_task, only: %i[show edit update move]

    def index
      @tasks = Task.includes(:assignee, :user, :rich_text_description, :images_attachments)
                   .order(:position).group_by(&:stage)
    end

    def show
      @pagy, @comments = pagy @task.comments.includes(:user).order(created_at: :desc)
    end

    def new
      @task = Task.new
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Добавить задачу'),
        turbo_stream.update(:modal_body, partial: '/admin/tasks/new')
      ]
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактировать задачу'),
        turbo_stream.update(:modal_body, partial: '/admin/tasks/edit')
      ]
    end

    def create
      @task = Task.new({ user: current_user }.merge(task_params))
      if @task.save
        generate_images_variants
        redirect_to admin_tasks_path, notice: t('.create')
      else
        error_notice @task.errors.full_messages
      end
    end

    def update
      if update_task_with_images
        render turbo_stream: [
          turbo_stream.replace(@task, partial: '/admin/tasks/task', locals: { task: @task }),
          success_notice(t('.update'))
        ]
      else
        error_notice @task.errors.full_messages
      end
    end

    def move
      return head :ok if task_params[:position] == @task.position && task_params[:stage] == @task.stage

      if @task.update(task_params)
        render json: { success: true }
      else
        render json: { errors: @task.errors.full_messages }, status: :unprocessable_content
      end
    end

    private

    def set_task
      @task = Task.find(params[:id])
    end

    def task_params
      params.require(:task).permit(
        :title, :priority, :user_id, :assignee_id, :start_date, :due_date, :stage, :category, :task_type,
        :deadline_notification_days, :position, :description, :price, images: [], files: []
      )
    end

    def generate_images_variants
      image_count = task_params[:images]&.compact_blank&.size.to_i
      return if image_count.zero? || !@task.images.attached?

      new_blob_ids = @task.images.attachments.last(image_count).pluck(:blob_id)
      GenerateImageVariantsJob.perform_later(new_blob_ids) if new_blob_ids.any?
    end

    def update_task_with_images
      new_task_params = task_params
      new_images      = task_params[:images].present? ? new_task_params.delete(:images).compact_blank : []
      success         = @task.update(new_task_params)
      if success && new_images.any?
        @task.images.attach(new_images)
        generate_images_variants
      end

      success
    end
  end
end
