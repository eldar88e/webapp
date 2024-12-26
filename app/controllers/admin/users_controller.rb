module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[edit update destroy]
    include Pagy::Backend

    def index
      @q_users = User.all.order(created_at: :desc).ransack(params[:q])
      @pagy, @users = pagy(@q_users.result, items: 20)
    end

    def edit
      render turbo_stream: [
        turbo_stream.update(:modal_title, 'Редактирование пользователя'),
        turbo_stream.update(:modal_body, partial: '/admin/users/edit')
      ]
    end

    def update
      if @user.update(user_params)
        render turbo_stream: [
          turbo_stream.replace(@user, partial: '/admin/users/user', locals: { user: @user }),
          success_notice('Данные пользователя успешно обновлены.')
        ]
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
