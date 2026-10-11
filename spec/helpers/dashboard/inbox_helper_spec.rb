# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::InboxHelper, type: :helper do
  describe '#inbox_icon' do
    it 'returns inline svg tag with appropriate icon for channel types' do
      inbox = double('Inbox', channel_type: 'Channel::WebWidget')
      expect(helper).to receive(:inline_svg_tag).with('dashboard_channel_web_widget.svg', class: 'link-icon', aria: { hidden: true }).and_return('<svg>widget</svg>')

      expect(helper.inbox_icon(inbox)).to eq('<svg>widget</svg>')
    end

    it 'handles email channel' do
      inbox = double('Inbox', channel_type: 'Channel::Email')
      expect(helper).to receive(:inline_svg_tag).with('dashboard_channel_email.svg', class: 'link-icon', aria: { hidden: true }).and_return('<svg>email</svg>')

      expect(helper.inbox_icon(inbox)).to eq('<svg>email</svg>')
    end

    it 'handles mobile widget channel' do
      inbox = double('Inbox', channel_type: 'Channel::MobileWidget')
      expect(helper).to receive(:inline_svg_tag).with('mobile_widget.svg', class: 'link-icon', aria: { hidden: true }).and_return('<svg>mobile</svg>')

      expect(helper.inbox_icon(inbox)).to eq('<svg>mobile</svg>')
    end
  end

  describe '#inbox_channel_tag_type' do
    it 'returns mobile-widget for Channel::MobileWidget' do
      inbox = double('Inbox', channel_type: 'Channel::MobileWidget')
      expect(helper.inbox_channel_tag_type(inbox)).to eq('mobile-widget')
    end
  end
end
