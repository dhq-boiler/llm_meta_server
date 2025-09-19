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
        redirect_to user_llm_api_keys_path, notice: "API key has been added successfully"
      rescue => e
        redirect_to user_llm_api_keys_path, method: :get, alert: "Failed to add API key: #{e.message}"
      end
    else
      redirect_to user_llm_api_keys_path, alert: "Please enter LLM type and API key"
    end
  end

  # PATCH/PUT /user/:user_id/keys/:id
  def update
    new_api_key = params[:api_key]
    description = params[:description]

    result = @user.update_llm_apikey(@llm_api_key.id, new_api_key, description)
    case result
    when :updated_both
      redirect_to user_llm_api_keys_path, notice: "API key and description have been updated successfully"
    when :updated_key
      redirect_to user_llm_api_keys_path, notice: "API key has been updated successfully"
    when :updated_description
      redirect_to user_llm_api_keys_path, notice: "Description of API key has been updated successfully"
    else
      redirect_to user_llm_api_keys_path, alert: "Please enter an API key"
    end
  end

  # DELETE /user/:user_id/keys/:id
  def destroy
    llm_type = @llm_api_key.llm_type

    if @llm_api_key.destroy
      redirect_to user_llm_api_keys_path, notice: "#{llm_type&.upcase} API key has been deleted successfully"
    else
      redirect_to user_llm_api_keys_path, alert: "Failed to delete API key"
    end
  end

  private

  def set_user
    @user = current_user
  end

  def set_llm_api_key
    @llm_api_key = @user.llm_api_keys.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to user_path(@user), alert: "The specified API key was not found"
  end

  # 必要に応じて使用できるStrong Parameters（現在は未使用）
  def llm_api_key_params
    params.require(:llm_api_key).permit(:llm_type, :api_key)
  end
end
