# frozen_string_literal: true

class RSVPDynamo < Dynamodb::Base
  key :user_id,   :string, key: :hash
  key :event_id,  :string, key: :range

  local_index   name: :event_date_index,
                key: { name: :event_date, type: :string },
                projection: :all

  global_index  name: :event_id_index,
                keys: {
                  hash: { name: :event_id, type: :string },
                  range: { name: :user_id, type: :string }
                },
                projection: :all

  ACCESSORS = [:user_id, :event_id, :event_date, :status].freeze

  ##
  # Example Queries:
  # rsvp = RSVPDynamo.find(user_id, event_id)
  #
  # Querying Main Table
  # RSVPDynamo.where(user_id: rsvp_1.user_id.to_s)
  #           .where(event_id: { eq: rsvp_1.artist_event_id.to_s }).all
  #
  # Querying Index
  # RSVPDynamo.where(index_name: :event_date_index)
  #           .where(user_id: rsvp_1.user_id.to_s)
  #           .where(event_date: { gt: Time.now.iso8601 })
  #           .where(status: { eq: 'unsure' }).all
end
