# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dynamodb do
  it "has a version number" do
    expect(Dynamodb::VERSION).to eq "0.3.0"
  end
end
