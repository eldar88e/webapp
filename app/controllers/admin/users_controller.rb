module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @q_users = User.all.order(created_at: :desc).ransack(params[:q])
      @pagy, @users = pagy(@q_users.result, items: 20)
    end

    def show
      @q_orders = @user.orders.order(created_at: :desc).ransack(params[:q])
      @pagy, @orders = pagy(@q_orders.result, items: 20)
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
          success_notice(t('controller.users.update'))
        ]
      else
        error_notice(@user.errors.full_messages, :unprocessable_entity)
      end
    end

    def destroy
      @user.destroy!
      redirect_to admin_users_path, status: :see_other, notice: t('controller.users.destroy')
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      base_params = %i[
        first_name middle_name last_name phone_number address postal_code street home apartment build email username
      ]
      base_params += %i[role tg_id] if current_user.admin?
      params.require(:user).permit(*base_params)
    end
  end
end
