class RemoveUniqueIndexFromLlmApiKeys < ActiveRecord::Migration[8.0]
  def change
    # ユニーク制約付きのインデックスを削除
    remove_index :llm_api_keys, [ :user_id, :llm_type ]

    # ユニーク制約なしの通常のインデックスを追加
    add_index :llm_api_keys, [ :user_id, :llm_type ]
  end
end
