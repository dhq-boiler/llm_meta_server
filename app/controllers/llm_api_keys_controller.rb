class LlmApiKeysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_llm_api_key, only: [ :update, :destroy ]

  # GET /user/:user_id/keys
  def index
    @llm_api_keys = @user.llm_api_keys
  end

  # POST /user/:user_id/keys
  def create
    llm_type = params[:llm_type]
    api_key = params[:api_key]
    description = params[:description]

    if llm_type.present? && api_key.present?
      begin
        @user.add_llm_apikey(llm_type, api_key, description)
        redirect_to user_llm_api_keys_path, notice: "API キーを追加しました"
      rescue => e
        redirect_to user_llm_api_keys_path, method: :get, alert: "API キーの追加に失敗しました: #{e.message}"
      end
    else
      redirect_to user_llm_api_keys_path, alert: "LLMタイプとAPI キーを入力してください"
    end
  end

  # PATCH/PUT /user/:user_id/keys/:id
  def update
    new_api_key = params[:api_key]
    description = params[:description]

    result = @user.update_llm_apikey(@llm_api_key.id, new_api_key, description)
    case result
    when :updated_both
      redirect_to user_llm_api_keys_path, notice: "API キーと説明を更新しました"
    when :updated_key
      redirect_to user_llm_api_keys_path, notice: "API キーを更新しました"
    when :updated_description
      redirect_to user_llm_api_keys_path, notice: "API キーの説明を更新しました"
    else
      redirect_to user_llm_api_keys_path, alert: "更新に失敗しました: #{@llm_api_key.errors.full_messages.join(', ')}"
    end
  end

  # DELETE /user/:user_id/keys/:id
  def destroy
    llm_type = @llm_api_key.llm_type

    if @llm_api_key.destroy
      redirect_to user_llm_api_keys_path, notice: "#{llm_type&.upcase} API キーを削除しました"
    else
      redirect_to user_llm_api_keys_path, alert: "API キーの削除に失敗しました"
    end
  end

  private

  def set_user
    @user = current_user
  end

  def set_llm_api_key
    @llm_api_key = @user.llm_api_keys.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to user_path(@user), alert: "指定されたAPI キーが見つかりません"
  end

  # 必要に応じて使用できるStrong Parameters（現在は未使用）
  def llm_api_key_params
    params.require(:llm_api_key).permit(:llm_type, :api_key)
  end
end
