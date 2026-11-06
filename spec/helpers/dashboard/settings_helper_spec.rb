# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::SettingsHelper, type: :helper do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, account: account, email: "support-#{SecureRandom.hex(4)}@example.com") }
  let(:widget_channel) { create(:channel_web_widget, account: account, allowed_hosts: [ 'https://example.com' ]) }
  let(:mobile_channel) { create(:channel_mobile_widget, account: account, name: "Capiller Rely iOS") }

  before do
    helper.default_url_options[:locale] = I18n.default_locale
  end

  describe '#channel_overview_type and label' do
    it 'returns mapped type and label' do
      expect(helper.channel_overview_type(email_channel)).to eq('email')
      expect(helper.channel_overview_type_label(email_channel)).to eq('Email')
      expect(helper.channel_overview_icon(email_channel)).to eq('email.svg')

      expect(helper.channel_overview_type(mobile_channel)).to eq('mobile_widget')
      expect(helper.channel_overview_type_label(mobile_channel)).to eq('Mobile App (SDK)')
      expect(helper.channel_overview_icon(mobile_channel)).to eq('mobile_widget.svg')
    end
  end

  describe '#channel_overview_identifier' do
    it 'extracts identifier from email channel' do
      expect(helper.channel_overview_identifier(email_channel)).to eq(email_channel.email)
    end

    it 'extracts identifier from web widget channel' do
      expect(helper.channel_overview_identifier(widget_channel)).to eq('https://example.com')
    end

    it 'extracts identifier from mobile widget channel' do
      expect(helper.channel_overview_identifier(mobile_channel)).to eq(mobile_channel.identifier)
    end
  end

  describe '#channel_show_details_partial and aside partial' do
    it 'returns correct partial paths for mobile widget' do
      expect(helper.channel_show_details_partial(mobile_channel)).to eq('dashboard/channels/mobile_widget/show_details')
      expect(helper.channel_show_aside_partial(mobile_channel)).to eq('dashboard/channels/mobile_widget/show_aside')
    end
  end

  describe '#channel_overview_policy' do
    it 'resolves mobile_widget_channel policy' do
      expect(helper).to receive(:policy).with(:mobile_widget_channel).and_return(double('Policy'))
      helper.channel_overview_policy(mobile_channel)
    end
  end

  describe '#channel_overview_edit_path and destroy_path' do
    it 'returns edit and destroy paths for channels' do
      expect(helper.channel_overview_edit_path(email_channel)).to eq(edit_channels_email_path(id: email_channel.id))
      expect(helper.channel_overview_destroy_path(email_channel)).to eq(channels_email_path(id: email_channel.id))

      expect(helper.channel_overview_edit_path(mobile_channel)).to eq(edit_channels_mobile_widget_path(id: mobile_channel.id))
      expect(helper.channel_overview_destroy_path(mobile_channel)).to eq(channels_mobile_widget_path(id: mobile_channel.id))
    end
  end
end
