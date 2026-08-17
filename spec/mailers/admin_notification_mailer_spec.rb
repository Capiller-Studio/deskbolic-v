# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminNotificationMailer, type: :mailer do
  describe '#workspace_request' do
    let(:account) { create(:account, email: 'admin@company.com') }
    let(:user) { create(:user, email: 'requesting_user@example.com', name: 'Bob') }
    let(:mail) { described_class.workspace_request(account, user) }

    it 'renders the headers and sends to account email' do
      expect(mail.subject).to eq('Workspace Joining Request')
      expect(mail.to).to eq([ 'admin@company.com' ])
    end
  end
end
