# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Csat::SurveyPolicy do
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:owner_account_user) { create(:account_user, account: account, user: owner_user, owner: true) }
  let(:survey) { create(:csat_survey, account: account) }

  before do
    Current.account = account
  end

  after do
    Current.account = nil
  end

  describe 'permissions' do
    context 'when custom_csat feature is enabled' do
      subject { described_class.new(owner_user, survey) }

      before do
        allow(account).to receive(:feature_enabled?).with(:custom_csat).and_return(true)
      end

      it 'permits index, new, create, edit, update, destroy' do
        expect(subject.index?).to be true
        expect(subject.new?).to be true
        expect(subject.create?).to be true
        expect(subject.edit?).to be true
        expect(subject.update?).to be true
        expect(subject.destroy?).to be true
      end
    end

    context 'when custom_csat feature is disabled' do
      subject { described_class.new(owner_user, survey) }

      before do
        allow(account).to receive(:feature_enabled?).with(:custom_csat).and_return(false)
      end

      it 'denies actions' do
        expect(subject.index?).to be false
        expect(subject.create?).to be false
      end
    end
  end
end
