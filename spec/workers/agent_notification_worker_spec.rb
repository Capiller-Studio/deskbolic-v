# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentNotificationWorker, type: :worker do
  let(:account) { create(:account) }
  let(:user) { create(:user, email: 'agent@example.com') }
  let!(:account_user) { create(:account_user, account: account, user: user) }
  let(:conversation) { create(:conversation, account: account) }

  it 'delivers notification mailer when email is enabled' do
    setting = NotificationSetting.find_or_create_by!(user: user, account: account)
    allow(setting).to receive(:email_enabled_for?).and_return(true)
    allow(NotificationSetting).to receive(:find_or_create_by!).and_return(setting)

    mailer_double = double('Mailer', deliver_later: true)
    allow(AgentNotificationMailer).to receive(:conversation_assigned).with(user, conversation).and_return(mailer_double)

    described_class.new.perform('conversation_assigned', 'Conversation', conversation.id, [ user.id ])

    expect(AgentNotificationMailer).to have_received(:conversation_assigned).with(user, conversation)
  end

  it 'skips delivery when user has disabled email notifications' do
    setting = NotificationSetting.find_or_create_by!(user: user, account: account)
    allow(setting).to receive(:email_enabled_for?).and_return(false)
    allow(NotificationSetting).to receive(:find_or_create_by!).and_return(setting)

    allow(AgentNotificationMailer).to receive(:conversation_assigned)

    described_class.new.perform('conversation_assigned', 'Conversation', conversation.id, [ user.id ])

    expect(AgentNotificationMailer).not_to have_received(:conversation_assigned)
  end
end
