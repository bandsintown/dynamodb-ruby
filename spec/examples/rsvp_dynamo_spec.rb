# # frozen_string_literal: true
#
# require "spec_helper"
# require "rsvp_dynamo"
# require "dynamodb/local"
#
# describe RSVPDynamo do
#   let(:rsvp_1) { rsvps(:rsvp_1) }
#   let(:rsvp_2) { rsvps(:rsvp_2) }
#   let(:rsvp_4) { rsvps(:rsvp_4) }
#   let(:rsvp_7) { rsvps(:rsvp_7) }
#   let(:rsvp_8) { rsvps(:rsvp_8) }
#   let(:rsvp_9) { rsvps(:rsvp_9) }
#   let(:rsvp_1_response) do
#     {
#       user_id: rsvp_1.user_id.to_s,
#       event_id: rsvp_1.artist_event_id.to_s,
#       event_date: rsvp_1.artist_event.datetime.iso8601,
#       status: rsvp_1.status
#     }.merge(timestamps).stringify_keys
#   end
#   let(:timestamps) do
#     {
#       updated_at: Time.now.utc.iso8601,
#       created_at: Time.now.utc.iso8601
#     }
#   end
#
#   before do
#     DynamoDBLocal.reset_class(RSVPDynamo)
#
#     RSVPDynamo.create(
#       {
#         user_id: rsvp_1.user_id.to_s,
#         event_id: rsvp_1.artist_event_id.to_s,
#         event_date: rsvp_1.artist_event.datetime.iso8601,
#         status: rsvp_1.status
#       }
#     )
#
#     RSVPDynamo.create(
#       {
#         user_id: rsvp_2.user_id.to_s,
#         event_id: rsvp_2.artist_event_id.to_s,
#         event_date: rsvp_2.artist_event.datetime.iso8601,
#         status: rsvp_2.status
#       }
#     )
#
#     RSVPDynamo.create(
#       {
#         user_id: rsvp_4.user_id.to_s,
#         event_id: rsvp_4.artist_event_id.to_s,
#         event_date: rsvp_4.artist_event.datetime.iso8601,
#         status: rsvp_4.status
#       }
#     )
#
#     RSVPDynamo.create(
#       {
#         user_id: rsvp_1.user_id.to_s,
#         event_id: rsvp_7.artist_event_id.to_s,
#         event_date: rsvp_7.artist_event.datetime.iso8601,
#         status: rsvp_7.status
#       }
#     )
#
#     RSVPDynamo.create(
#       {
#         user_id: rsvp_1.user_id.to_s,
#         event_id: rsvp_8.artist_event_id.to_s,
#         event_date: rsvp_8.artist_event.datetime.iso8601,
#         status: rsvp_8.status
#       }
#     )
#
#     RSVPDynamo.create(
#       {
#         user_id: rsvp_1.user_id.to_s,
#         event_id: rsvp_9.artist_event_id.to_s,
#         event_date: rsvp_9.artist_event.datetime.iso8601,
#         status: rsvp_9.status
#       }
#     )
#   end
#
#   describe '#find(p_key, s_key)' do
#     it 'should find the rsvp with user_id and event_id' do
#       rsvp = RSVPDynamo.find(rsvp_1.user_id.to_s, rsvp_1.artist_event_id.to_s)
#       expect(rsvp.data).to eq(rsvp_1_response)
#     end
#   end
#
#   describe '#where(options)' do
#     it 'should query the main table for event that user RSVPd to' do
#
#       rsvps =
#         RSVPDynamo.where(user_id: rsvp_1.user_id.to_s)
#                   .where(event_id: { eq: rsvp_1.artist_event_id.to_s }).all
#
#       expect(rsvps.items[0].data).to eq(
#         {
#           user_id: rsvp_1.user_id.to_s,
#           event_id: rsvp_1.artist_event_id.to_s,
#           event_date: rsvp_1.artist_event.datetime.iso8601,
#           status: rsvp_1.status
#         }.merge(timestamps).with_indifferent_access
#       )
#     end
#
#     it 'should query the index for upcoming events' do
#       rsvps =
#         RSVPDynamo.where(index_name: :event_date_index)
#                   .where(user_id: rsvp_1.user_id.to_s)
#                   .where(event_date: { gt: Time.now.iso8601 })
#                   .where(status: { eq: 'unsure' }).all
#
#       expect(rsvps.items[0].data).to eq(
#         {
#           user_id: rsvp_1.user_id.to_s,
#           event_id: rsvp_9.artist_event_id.to_s,
#           event_date: rsvp_9.artist_event.datetime.iso8601,
#           status: rsvp_9.status
#         }.merge(timestamps).with_indifferent_access
#       )
#     end
#
#     context 'when querying global index' do
#       it 'should query the global index for users RSVPing to event' do
#         rsvps =
#           RSVPDynamo.where(index_name: :event_id_index)
#                     .where(event_id: rsvp_1.artist_event_id.to_s)
#                     .select('user_id').all
#
#         expect(rsvps.items.map(&:data)).to eq(
#           [
#             { user_id: rsvp_4.user_id.to_s }.with_indifferent_access,
#             { user_id: rsvp_1.user_id.to_s }.with_indifferent_access,
#             { user_id: rsvp_2.user_id.to_s }.with_indifferent_access
#           ]
#         )
#       end
#     end
#   end
# end
