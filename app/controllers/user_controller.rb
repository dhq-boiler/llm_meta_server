class UserController < ApplicationController
  before_action :set_user, only: [ :show ]
  def show
    @user = current_user
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:email)
  end
end
