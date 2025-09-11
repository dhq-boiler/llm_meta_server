class User < ApplicationRecord
  devise :registerable, :omniauthable, omniauth_providers: %i[google_oauth2]

  has_many :llm_api_keys, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :google_id, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.google_id = auth.uid
    end
  end

  # 認証プロバイダーを判定するメソッド
  def authentication_provider
    return :google_oauth2 if google_id.present?
    # 将来的に他のIdPを追加する場合はここに条件を追加
    # return :azure_oauth2 if azure_id.present?
    # return :github if github_id.present?

    :unknown
  end

  # Google SSOユーザーかどうかを判定
  def google_sso_user?
    authentication_provider == :google_oauth2
  end

  # SSO（シングルサインオン）ユーザーかどうかを判定
  def sso_user?
    authentication_provider != :unknown
  end

  # 認証プロバイダーの表示名を取得
  def authentication_provider_name
    case authentication_provider
    when :google_oauth2
      "Google"
    else
      "不明"
    end
  end
end
