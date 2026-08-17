# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::InboxHelper, type: :helper do
  describe '#inbox_icon' do
    it 'returns inline svg tag with appropriate icon for channel types' do
      inbox = double('Inbox', channel_type: 'Channel::WebWidget')
      expect(helper).to receive(:inline_svg_tag).with('widget.svg', class: 'link-icon', alt: 'inbox icon').and_return('<svg>widget</svg>')

      expect(helper.inbox_icon(inbox)).to eq('<svg>widget</svg>')
    end

    it 'handles email channel' do
      inbox = double('Inbox', channel_type: 'Channel::Email')
      expect(helper).to receive(:inline_svg_tag).with('email.svg', class: 'link-icon', alt: 'inbox icon').and_return('<svg>email</svg>')

      expect(helper.inbox_icon(inbox)).to eq('<svg>email</svg>')
    end
  end
end
