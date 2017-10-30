# frozen_string_literal: true

require "dynamodb/base"

class DynamodbStub < Dynamodb::Base
  key :hash_key,   :number, key: :hash
  key :range_key,  :string, key: :range

  local_index name: :stub_local_index,
              key: { name: :local_index_key, type: :string },
              projection: :all

  local_index name: :another_local_index,
              key: { name: :another_index_key, type: :string },
              projection: :all

  global_index  name: :stub_global_index,
                keys: {
                  hash: { name: :global_hash_key, type: :string },
                  range: { name: :global_range_key, type: :string }
                },
                projection: :all

  time_to_live { @data["expires_at"] = (DateTime.now >> 3).to_time.to_i }
end
