# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Channels::CustomHelper, type: :helper do
  let(:account) { create(:account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe '#custom_channel_response_mapping_options' do
    it 'returns base customer, message, and conversation attribute options' do
      options = helper.custom_channel_response_mapping_options(account)
      expect(options).to have_key('Customer Attributes')
      expect(options).to have_key('Message Attributes')
      expect(options).to have_key('Conversation Attributes')
    end

    it 'includes custom fields when configured on account' do
      create(:custom_field, account: account, entity_type: :customer, key: 'loyalty_tier')
      options = helper.custom_channel_response_mapping_options(account)
      expect(options).to have_key('Customer Custom Attributes')
      expect(options['Customer Custom Attributes']).to include([ 'Loyalty Tier', 'customer.custom_attributes.loyalty_tier' ])
    end
  end
end
