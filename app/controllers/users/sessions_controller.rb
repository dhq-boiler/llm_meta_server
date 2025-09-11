class Users::SessionsController < Devise::SessionsController
  def destroy
    # 現在のユーザーの認証プロバイダーを記録
    @user_provider = current_user&.authentication_provider
    @provider_name = current_user&.authentication_provider_name

    # セッションを削除（Google SSO専用）
    if current_user
      sign_out(current_user)
      reset_session
    end

    # SSOユーザーの場合は認証プロバイダー固有のログアウトページへ
    if @user_provider && @user_provider != :unknown
      redirect_to "/users/sessions/sso_logout?provider=#{@user_provider}"
    else
      redirect_to root_path, notice: "Successfully signed out."
    end
  end

  def sso_logout
    # SSO（各IdP）のログアウト確認ページを表示
    @provider = params[:provider]&.to_sym || :google_oauth2
    @provider_name = provider_display_name(@provider)
    @logout_url = provider_logout_url(@provider)

    render "sso_logout"
  end

  private


  # 認証プロバイダーの表示名を取得
  def provider_display_name(provider)
    case provider
    when :google_oauth2
      "Google"
    else
      "不明"
    end
  end

  # 各認証プロバイダーのログアウトURLを取得
  def provider_logout_url(provider)
    case provider
    when :google_oauth2
      "https://accounts.google.com/logout"
    else
      root_url
    end
  end
end
