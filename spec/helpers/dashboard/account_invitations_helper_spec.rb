# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AccountInvitationsHelper, type: :helper do
  let(:account) { create(:account) }
  let(:role) do
    create(:access_role, account: account, permissions: {
      'conversations' => { 'read' => true, 'write' => true },
      'inboxes' => { 'read' => true }
    })
  end

  describe '#invitation_permission_labels' do
    it 'returns humanized action and resource labels' do
      labels = helper.invitation_permission_labels(role)
      expect(labels).to be_an(Array)
      expect(labels.length).to eq(3)
    end
  end

  describe '#invitation_permission_labels_for' do
    it 'returns unique combined labels for multiple roles' do
      role2 = create(:access_role, account: account, permissions: {
        'conversations' => { 'read' => true },
        'teams' => { 'manage' => true }
      })
      labels = helper.invitation_permission_labels_for([ role, role2 ])
      expect(labels.length).to eq(4)
    end
  end

  describe '#invitation_role_description' do
    it 'returns summary of permissions and areas' do
      description = helper.invitation_role_description(role)
      expect(description).to include('3 permissions')
      expect(description).to include('2 areas')
    end
  end

  describe '#invitation_visible_permissions and remaining counts' do
    let(:labels) { %w[Label1 Label2 Label3 Label4 Label5 Label6] }

    it 'returns first N permissions' do
      visible = helper.invitation_visible_permissions(labels, limit: 3)
      expect(visible).to eq(%w[Label1 Label2 Label3])
    end

    it 'calculates remaining count correctly' do
      expect(helper.invitation_remaining_permissions_count(labels, limit: 3)).to eq(3)
      expect(helper.invitation_remaining_permissions_count(labels, limit: 10)).to eq(0)
    end
  end
end
