# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dynamodb do
  it "has a version number" do
    expect(Dynamodb::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
