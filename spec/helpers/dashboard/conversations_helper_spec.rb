# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ConversationsHelper, type: :helper do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#single_emoji_message?' do
    it 'returns true for a single standard emoji' do
      expect(helper.single_emoji_message?('👍')).to be true
      expect(helper.single_emoji_message?('🔥')).to be true
      expect(helper.single_emoji_message?('🎉')).to be true
    end

    it 'returns false for multiple emojis or mixed text' do
      expect(helper.single_emoji_message?('👍🔥')).to be false
      expect(helper.single_emoji_message?('Hello 👍')).to be false
      expect(helper.single_emoji_message?('Just text')).to be false
      expect(helper.single_emoji_message?('')).to be false
      expect(helper.single_emoji_message?(nil)).to be false
    end
  end

  describe '#assigned_conversation and #assigned_team' do
    let(:team) { create(:team, account: account) }

    before do
      assign(:conversation, conversation)
    end

    it 'checks assignment status and team' do
      allow(conversation).to receive_messages(assigned?: true, team: team)

      expect(helper.assigned_conversation).to be true
      expect(helper.assigned_team).to eq(team)
    end
  end
end
