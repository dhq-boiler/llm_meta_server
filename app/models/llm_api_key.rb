class LlmApiKey < ApplicationRecord
  belongs_to :user

  validates :uuid, uniqueness: true
  validates :llm_type, presence: true
  validate :llm_type_must_be_supported
  validates :description, length: { maximum: 255 }, allow_blank: true

  before_validation :set_uuid
  before_validation :initialize_encryptable_api_key

  LLM_SERVICES = {
    "ollama" => :ollama,
    "openai" => :openai,
    "anthropic" => :anthropic,
    "google" => :gemini
  }.freeze

  def encryptable_api_key
    @encryptable_api_key ||= EncryptableApiKey.new(encrypted_api_key: encrypted_api_key)
  end

  def encryptable_api_key=(encryptable_api_key)
    raise ArgumentError, "encryptable_api_key cannot be nil" if encryptable_api_key.nil?

    @encryptable_api_key = encryptable_api_key
    self.encrypted_api_key = encryptable_api_key.encrypted_api_key
  end

  def llm_rb_method
    LLM_SERVICES[self.llm_type.downcase]
  end

  def llm_type_for_display
    self[:llm_type].capitalize.gsub("Openai", "OpenAI")
  end

  def as_json(options = {})
    super({ only: %i[uuid llm_type description] }.merge(options)).tap do |json|
      json["available_models"] = LlmModelMap.available_models_for llm_type
    end
  end

  def self.llm_types_for_select
    LLM_SERVICES.keys.map { |type| [ type.capitalize.gsub("Openai", "OpenAI"), type ] }
  end

  private

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def initialize_encryptable_api_key
    # encrypted_api_keyが設定されている場合のみ初期化
    @encryptable_api_key ||= EncryptableApiKey.new(encrypted_api_key: encrypted_api_key) if encrypted_api_key.present?
  end

  def llm_type_must_be_supported
    return if llm_type.blank?

    unless LLM_SERVICES.keys.include?(llm_type)
      errors.add(:llm_type, "#{llm_type} is not a supported LLM type")
    end
  end
end
