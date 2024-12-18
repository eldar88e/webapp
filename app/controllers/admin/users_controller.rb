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

    def edit; end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: 'Данные пользователя успешно обновлены.'
      else
        render :edit, status: :unprocessable_entity
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
      params.require(:user).permit(:first_name, :middle_name, :last_name) # TODO: нужное выбрать
    end
  end
end
