# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::SettingsHelper, type: :helper do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, account: account, email: "support-#{SecureRandom.hex(4)}@example.com") }
  let(:widget_channel) { create(:channel_web_widget, account: account, allowed_hosts: [ 'https://example.com' ]) }

  before do
    helper.default_url_options[:locale] = I18n.default_locale
  end

  describe '#channel_overview_type and label' do
    it 'returns mapped type and label' do
      expect(helper.channel_overview_type(email_channel)).to eq('email')
      expect(helper.channel_overview_type_label(email_channel)).to eq('Email')
      expect(helper.channel_overview_icon(email_channel)).to eq('email.svg')
    end
  end

  describe '#channel_overview_identifier' do
    it 'extracts identifier from email channel' do
      expect(helper.channel_overview_identifier(email_channel)).to eq(email_channel.email)
    end

    it 'extracts identifier from web widget channel' do
      expect(helper.channel_overview_identifier(widget_channel)).to eq('https://example.com')
    end
  end

  describe '#channel_overview_edit_path and destroy_path' do
    it 'returns edit and destroy paths for channels' do
      expect(helper.channel_overview_edit_path(email_channel)).to eq(edit_channels_email_path(id: email_channel.id))
      expect(helper.channel_overview_destroy_path(email_channel)).to eq(channels_email_path(id: email_channel.id))
    end
  end
end
