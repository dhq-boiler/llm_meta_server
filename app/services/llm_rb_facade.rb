module LlmRbFacade
  class << self
    def call!(llm_api_key, model_name, prompt)
      llm = create_llm_client llm_api_key
      model_id = find_model_id llm, model_name

      execute_chat! llm, model_id, prompt
    end

    def available_models_for(llm_api_key)
      llm = create_llm_client llm_api_key
      llm.models.all.map { it.id || it.name.gsub(/^models\//, "") } # Google LLM uses 'name' instead of 'id' and prefixes model_id with 'models/'
    end

    def create_llm_client(llm_api_key)
      llm_rb_method = llm_api_key.llm_rb_method

      # public_send dynamically invokes a public method on an object
      # Example: LLM.public_send(:openai, key: "xxx") is equivalent to LLM.openai(key: "xxx")
      # Unlike send, public_send cannot call private methods (safer)
      # Here, it calls one of :ollama, :openai, :anthropic, or :gemini based on llm_type
      # This eliminates the need for separate files for each LLM service
      LLM.public_send llm_rb_method, key: llm_api_key.encryptable_api_key.plain_api_key
    end

    def find_model_id(llm, model_name)
      model = llm.models.all.find { it.id == model_name || it.name == "models/" + model_name }
      raise ModelNotFoundError, model_name unless model

      model.id || model.name.gsub(/^models\//, "") # Google LLM uses 'name' instead of 'id' and prefixes model_id with 'models/'
    end

    def execute_chat!(llm, model_id, prompt)
      bot = LLM::Bot.new llm, model: model_id
      messages = bot.chat { it.user prompt }

      messages.map { it.content }.join "\n"
    end
  end
end
