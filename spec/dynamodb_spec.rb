# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dynamodb do
  it "has a version number" do
    expect(Dynamodb::VERSION).to eq "0.3.0"
  end

  # describe "#configure" do
  #   before do
  #     Dynamodb.configure do |config|
  #       config.client_settings = { endpoint: 'www.dynamodb.com' }
  #     end
  #   end
  #
  #   it "returns the correct client settings" do
  #     dynamodb = Dynamodb::Base.client_settings
  #
  #     expect(dynamodb.client_settings).to eq({ endpoint: 'www.dynamodb.com' })
  #   end
  # end
end
