# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dynamodb::Configuration do
  let(:subject) { Dynamodb::Configuration.new() }

  describe ".initialize" do
    it { expect(subject.client_config).to eq({ stub_responses: true }) }

    it { expect(subject.can_create_tables).to eq(false) }

    it { expect(subject.can_delete_tables).to eq(false) }
  end
end
