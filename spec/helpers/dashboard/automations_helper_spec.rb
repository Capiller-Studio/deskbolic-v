# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AutomationsHelper, type: :helper do
  let(:account) { create(:account) }
  let(:user) { create(:user, name: 'Alice') }
  let!(:account_user) { create(:account_user, account: account, user: user) }
  let!(:team) { create(:team, account: account, name: 'Support') }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe '#event_options_for_type' do
    it 'returns event options for event_trigger' do
      options = helper.event_options_for_type('event_trigger')
      expect(options).to be_an(Array)
      expect(options.map(&:last)).to include('conversation.created', 'message.created')
    end

    it 'returns event options for time_trigger' do
      options = helper.event_options_for_type('time_trigger')
      expect(options.map(&:last)).to include('hours_since_created', 'hours_since_last_activity')
    end
  end

  describe '#condition_attribute_options and condition_operator_options' do
    it 'returns valid condition attributes and operators' do
      expect(helper.condition_attribute_options).not_to be_empty
      expect(helper.condition_operator_options).not_to be_empty
      expect(helper.action_type_options).not_to be_empty
    end
  end

  describe '#agent_options_for_select and #team_options_for_select' do
    it 'returns account users and teams' do
      expect(helper.agent_options_for_select).to include([ 'Alice', user.id ])
      expect(helper.team_options_for_select).to include([ 'Support', team.id ])
    end
  end
end
