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

  describe 'SLA Helpers' do
    let(:sla_policy) { create(:sla_policy, account: account) }

    describe '#conversation_sla_badge_text and #conversation_sla_badge_class' do
      it 'returns N/A when there are no SLAs' do
        expect(helper.conversation_sla_badge_text(conversation)).to eq('N/A')
        expect(helper.conversation_sla_badge_class(conversation)).to eq('')
      end

      it 'returns Breached and text-danger when any SLA has failed' do
        create(:conversation_sla, account: account, conversation: conversation, sla_policy: sla_policy, status: :failed)

        expect(helper.conversation_sla_badge_text(conversation)).to eq('Breached')
        expect(helper.conversation_sla_badge_class(conversation)).to eq('text-danger')
      end

      it 'returns Achieved and text-success when all SLAs are successful' do
        create(:conversation_sla, account: account, conversation: conversation, sla_policy: sla_policy, status: :successful)

        expect(helper.conversation_sla_badge_text(conversation)).to eq('Achieved')
        expect(helper.conversation_sla_badge_class(conversation)).to eq('text-success')
      end

      it 'returns On track when SLAs are pending and not breached' do
        create(:conversation_sla, account: account, conversation: conversation, sla_policy: sla_policy, status: :pending)

        expect(helper.conversation_sla_badge_text(conversation)).to eq('On track')
        expect(helper.conversation_sla_badge_class(conversation)).to eq('')
      end
    end

    describe '#conversation_sla_status_text and #conversation_sla_status_class' do
      let(:sla) { create(:conversation_sla, account: account, conversation: conversation, sla_policy: sla_policy) }

      it 'returns Breached and text-danger for failed SLA' do
        sla.update!(status: :failed)
        expect(helper.conversation_sla_status_text(sla)).to eq('Breached')
        expect(helper.conversation_sla_status_class(sla)).to eq('text-danger')
      end

      it 'returns Achieved and text-success for successful SLA' do
        sla.update!(status: :successful)
        expect(helper.conversation_sla_status_text(sla)).to eq('Achieved')
        expect(helper.conversation_sla_status_class(sla)).to eq('text-success')
      end

      it 'returns On track for active pending SLA' do
        sla.update!(status: :pending)
        expect(helper.conversation_sla_status_text(sla)).to eq('On track')
        expect(helper.conversation_sla_status_class(sla)).to eq('')
      end
    end
  end
end
