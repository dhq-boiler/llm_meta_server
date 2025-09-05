class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    if user_signed_in?
      redirect_to user_profile_path
    else
      # 未認証ユーザー向けのランディングページ
    end
  end
end
