# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Channels::WhatsappHelper, type: :helper do
  describe '#whatsapp_country_codes' do
    it 'returns list of country names and calling codes' do
      codes = helper.whatsapp_country_codes
      expect(codes).to be_an(Array)
      expect(codes).to include([ '🇺🇸 United States (+1)', '1' ])
      expect(codes).to include([ '🇬🇧 United Kingdom (+44)', '44' ])
    end
  end
end
