# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::EmailTemplateLayoutPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:layout) { create(:email_template_layout, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when email_templates feature is enabled' do
      subject { described_class.new(owner_user, layout) }

      before do
        allow(account).to receive(:feature_enabled?).with(:email_templates).and_return(true)
      end

      it 'permits index, edit, update, publish, discard_draft, preview' do
        expect(subject.index?).to be true
        expect(subject.edit?).to be true
        expect(subject.update?).to be true
        expect(subject.publish?).to be true
        expect(subject.discard_draft?).to be true
        expect(subject.preview?).to be true
      end
    end

    context 'when email_templates feature is disabled' do
      subject { described_class.new(owner_user, layout) }

      before do
        allow(account).to receive(:feature_enabled?).with(:email_templates).and_return(false)
      end

      it 'denies access' do
        expect(subject.index?).to be false
        expect(subject.update?).to be false
      end
    end
  end
end
