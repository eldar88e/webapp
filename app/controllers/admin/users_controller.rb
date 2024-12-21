module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[edit update destroy]
    include Pagy::Backend

    def index
      @q_users = User.all.order(created_at: :desc).ransack(params[:q])
      @pagy, @users = pagy(@q_users.result, items: 20)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_users_path, notice: 'User was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактирование пользователя'),
        turbo_stream.update(:modal_body, partial: '/admin/users/edit')
      ]
    end

    def update
      if @user.update(user_params)
        render turbo_stream: success_notice('Данные пользователя успешно обновлены.')
        # TODO: обновить во фронте обновленного пользователя
      else
        error_notice(@user.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @user.destroy!
      redirect_to admin_users_path, status: :see_other, notice: 'Пользователь успешно удален.'
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :middle_name, :last_name, :email) # TODO: нужное выбрать
    end
  end
end
