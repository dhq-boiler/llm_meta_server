class ApiKeyManager
  def retrieve_key(user, uuid)
    # キャッシュキーを生成（ユーザーID、UUID、LLM API Keyの更新日時を含める）
    llm_api_key = user.llm_api_keys.find_by(uuid: uuid)
    return nil unless llm_api_key

    cache_key = "api_key:#{user.id}:#{uuid}:#{llm_api_key.updated_at.to_i}"

    # キャッシュから取得を試行、なければ復号化して保存
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      Rails.logger.info "Decrypting API key for user #{user.id}, UUID: #{uuid}"
      # キーリストにこのキャッシュキーを追加
      add_to_cache_key_list(user.id, cache_key)
      llm_api_key.plain_api_key
    end
  end

  # API キーが更新された際にキャッシュを無効化するメソッド
  def invalidate_cache(user, uuid)
    # 特定のUUIDに関連するキャッシュキーを個別に削除
    cache_keys = get_cache_keys_for_uuid(user.id, uuid)
    cache_keys.each { |key| Rails.cache.delete(key) }
    remove_from_cache_key_list(user.id, cache_keys)
  end

  # ユーザーの全API キーキャッシュを無効化
  def invalidate_all_user_cache(user)
    # ユーザーの全キャッシュキーを取得して個別に削除
    cache_keys = get_user_cache_keys(user.id)
    cache_keys.each { |key| Rails.cache.delete(key) }
    clear_cache_key_list(user.id)
  end

  private

  # キャッシュキーリストにキーを追加
  def add_to_cache_key_list(user_id, cache_key)
    list_key = "cache_keys:user:#{user_id}"
    keys = Rails.cache.read(list_key) || []
    keys << cache_key unless keys.include?(cache_key)
    Rails.cache.write(list_key, keys, expires_in: 2.hours)
  end

  # 特定UUIDのキャッシュキーを取得
  def get_cache_keys_for_uuid(user_id, uuid)
    list_key = "cache_keys:user:#{user_id}"
    keys = Rails.cache.read(list_key) || []
    keys.select { |key| key.include?(":#{uuid}:") }
  end

  # ユーザーの全キャッシュキーを取得
  def get_user_cache_keys(user_id)
    list_key = "cache_keys:user:#{user_id}"
    Rails.cache.read(list_key) || []
  end

  # キャッシュキーリストからキーを削除
  def remove_from_cache_key_list(user_id, cache_keys)
    list_key = "cache_keys:user:#{user_id}"
    keys = Rails.cache.read(list_key) || []
    keys -= cache_keys
    if keys.empty?
      Rails.cache.delete(list_key)
    else
      Rails.cache.write(list_key, keys, expires_in: 2.hours)
    end
  end

  # キャッシュキーリストをクリア
  def clear_cache_key_list(user_id)
    list_key = "cache_keys:user:#{user_id}"
    Rails.cache.delete(list_key)
  end
end
