# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::EmailTemplatePolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:email_template) { create(:email_template, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when email_templates feature is enabled' do
      subject { described_class.new(owner_user, email_template) }

      before do
        allow(account).to receive(:feature_enabled?).with(:email_templates).and_return(true)
      end

      it 'permits index, edit, update, create, destroy, publish, discard_draft, preview, send_test, variables' do
        expect(subject.index?).to be true
        expect(subject.edit?).to be true
        expect(subject.update?).to be true
        expect(subject.create?).to be true
        expect(subject.destroy?).to be true
        expect(subject.publish?).to be true
        expect(subject.discard_draft?).to be true
        expect(subject.preview?).to be true
        expect(subject.send_test?).to be true
        expect(subject.variables?).to be true
      end
    end

    context 'when email_templates feature is disabled' do
      subject { described_class.new(owner_user, email_template) }

      before do
        allow(account).to receive(:feature_enabled?).with(:email_templates).and_return(false)
      end

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
      end
    end
  end
end
