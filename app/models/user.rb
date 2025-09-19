class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: %i[google_oauth2]

  has_many :llm_api_keys, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :google_id, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.google_id = auth.uid
    end
  end

  # Add API key
  def add_llm_apikey(llm_type, api_key, description)
    # Encrypt and save new API key
    encrypted_key = ApiKeyEncrypter.new.encrypt(api_key)

    llm_api_keys.create!(
      uuid: SecureRandom.uuid,
      llm_type: llm_type,
      encrypted_api_key: encrypted_key,
      description: description
    )
  end

  # Update API key
  def update_llm_apikey(key_id, new_api_key, description)
    llm_api_key = llm_api_keys.find(key_id)

    if new_api_key.present? && description.present?
      encrypted_key = ApiKeyEncrypter.new.encrypt(new_api_key)

      llm_api_key.update!(
        encrypted_api_key: encrypted_key,
        description: description
      )

      :updated_both
    elsif new_api_key.present?
      encrypted_key = ApiKeyEncrypter.new.encrypt(new_api_key)

      llm_api_key.update!(
        encrypted_api_key: encrypted_key
      )

      :updated_key
    elsif description.present?
      llm_api_key.update!(
        description: description
      )

      :updated_description
    else
      raise ArgumentError, "Please enter a new API key or description"
    end
  end

  # Delete API key (safe deletion)
  def remove_llm_apikey(key_id)
    llm_api_key = llm_api_keys.find_by(id: key_id)

    unless llm_api_key
      raise ActiveRecord::RecordNotFound, "The specified API key was not found"
    end

    # Delete within transaction
    ActiveRecord::Base.transaction do
      # Clean up related data
      cleanup_related_data(llm_api_key)

      # Delete API key
      llm_api_key.destroy!

      Rails.logger.info "User #{id} successfully removed API key #{llm_api_key.uuid}"
    end

    llm_api_key
  end

  private

  # Clean up related data
  def cleanup_related_data(llm_api_key)
    # Invalidate cache
    ApiKeyManager.new.invalidate_cache(self, llm_api_key.uuid)
  end
end
