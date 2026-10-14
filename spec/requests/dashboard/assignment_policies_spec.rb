# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::AssignmentPolicies', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan,
      features: { 'assignment_policies' => true, 'roles' => true, 'business_hours' => true },
      limits: { 'assignment_policies' => 10, 'users' => 10 }
    )
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { account.with_shard { create(:inbox, account: account) } }
  let(:business_hour_group) { account.with_shard { create(:business_hour_group, account: account, name: 'Support Shift') } }
  let(:policy) do
    account.with_shard do
      create(:assignment_policy,
        account: account,
        name: 'Tier 1 Round Robin',
        strategy: :round_robin,
        status: :active,
        position: 1
      )
    end
  end

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /assignment_policies' do
    it 'renders the assignment policies index with tab filters' do
      policy
      get assignment_policies_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tier 1 Round Robin')
    end

    it 'filters policies by strategy param' do
      policy
      account.with_shard do
        create(:assignment_policy, account: account, name: 'Load Balanced Policy', strategy: :load_balanced)
      end

      get assignment_policies_path(strategy: :round_robin, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tier 1 Round Robin')
      expect(response.body).not_to include('Load Balanced Policy')
    end
  end

  describe 'GET /assignment_policies/:id' do
    it 'renders the policy show page' do
      get assignment_policy_path(policy, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tier 1 Round Robin')
    end
  end

  describe 'GET /assignment_policies/new' do
    it 'renders the new policy form' do
      get new_assignment_policy_path(locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('assignment_policy[name]')
      expect(response.body).to include('assignment_policy[strategy]')
    end
  end

  describe 'GET /assignment_policies/:id/edit' do
    it 'renders the edit policy form' do
      get edit_assignment_policy_path(policy, locale: :en)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tier 1 Round Robin')
    end
  end

  describe 'POST /assignment_policies' do
    context 'with valid attributes' do
      let(:policy_name) { "Customer Support Routing #{SecureRandom.hex(4)}" }

      it 'creates an assignment policy and associates inboxes' do
        expect {
          post assignment_policies_path(locale: :en), params: {
            assignment_policy: {
              name: policy_name,
              description: 'Evenly distributes tickets',
              strategy: 'round_robin',
              status: 'active',
              max_conversations_per_agent: 5,
              respect_business_hours: '1',
              business_hour_group_id: business_hour_group.id,
              reassign_on_offline: '1',
              notify_on_assignment: '1',
              inbox_ids: [ inbox.id ]
            }
          }
        }.to change {
          account.with_shard { AssignmentPolicy.count }
        }.by(1)

        expect(response).to redirect_to(assignment_policies_path)
        follow_redirect!
        expect(response.body).to include(policy_name)

        created_policy = account.with_shard { AssignmentPolicy.find_by(name: policy_name) }
        expect(account.with_shard { created_policy.inboxes.pluck(:id) }).to include(inbox.id)
        expect(created_policy.business_hour_group_id).to eq(business_hour_group.id)
        expect(created_policy.max_conversations_per_agent).to eq(5)
      end
    end

    context 'with invalid attributes' do
      it 'renders new with unprocessable_entity when name is blank' do
        expect {
          post assignment_policies_path(locale: :en), params: {
            assignment_policy: {
              name: '',
              strategy: 'round_robin'
            }
          }
        }.not_to change { account.with_shard { AssignmentPolicy.count } }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'fails validation when respect_business_hours is true but business_hour_group_id is blank' do
        expect {
          post assignment_policies_path(locale: :en), params: {
            assignment_policy: {
              name: 'Invalid BH Policy',
              strategy: 'round_robin',
              respect_business_hours: '1',
              business_hour_group_id: ''
            }
          }
        }.not_to change { account.with_shard { AssignmentPolicy.count } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /assignment_policies/:id' do
    it 'updates policy attributes and synced inboxes' do
      new_inbox = account.with_shard { create(:inbox, account: account, name: 'VIP Inbox') }

      patch assignment_policy_path(policy, locale: :en), params: {
        assignment_policy: {
          name: 'Updated Tier 1 Routing',
          max_conversations_per_agent: 8,
          inbox_ids: [ new_inbox.id ]
        }
      }

      expect(response).to redirect_to(assignment_policies_path)
      policy.reload
      expect(policy.name).to eq('Updated Tier 1 Routing')
      expect(policy.max_conversations_per_agent).to eq(8)
      expect(account.with_shard { policy.inboxes.pluck(:id) }).to eq([ new_inbox.id ])
    end
  end

  describe 'PATCH /assignment_policies/:id/toggle' do
    it 'toggles the policy active/inactive status' do
      expect(policy.status).to eq('active')

      patch toggle_assignment_policy_path(policy, locale: :en)
      expect(response).to redirect_to(assignment_policies_path)
      expect(policy.reload.status).to eq('inactive')

      patch toggle_assignment_policy_path(policy, locale: :en), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(policy.reload.status).to eq('active')
    end
  end

  describe 'PATCH /assignment_policies/reorder' do
    let(:policy2) do
      account.with_shard do
        create(:assignment_policy, account: account, name: 'Policy 2', position: 2)
      end
    end

    it 'reorders policies positions' do
      patch reorder_assignment_policies_path(locale: :en), params: {
        ordered_ids: [ policy2.id, policy.id ]
      }
      expect(response).to have_http_status(:ok)
      expect(policy.reload.position).to eq(2)
      expect(policy2.reload.position).to eq(1)
    end

    it 'returns bad_request if ordered_ids is empty' do
      patch reorder_assignment_policies_path(locale: :en), params: { ordered_ids: [] }, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'DELETE /assignment_policies/:id' do
    it 'destroys the policy via HTML' do
      policy
      expect {
        delete assignment_policy_path(policy, locale: :en)
      }.to change { account.with_shard { AssignmentPolicy.count } }.by(-1)

      expect(response).to redirect_to(assignment_policies_path)
    end

    it 'destroys the policy via turbo_stream' do
      policy
      delete assignment_policy_path(policy, locale: :en), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(account.with_shard { AssignmentPolicy.where(id: policy.id) }).not_to exist
    end
  end

  describe 'Role-based access control' do
    let(:agent_user) { create(:user, confirmed_at: Time.current) }
    let!(:agent_account_user) { create(:account_user, account: account, user: agent_user, owner: false) }
    let(:restricted_role) do
      account.with_shard do
        create(:access_role,
          account: account,
          name: 'Restricted Support',
          permissions: { 'conversations' => { 'read' => true } }
        )
      end
    end

    before do
      agent_account_user.assign_roles([ restricted_role.id ])
      sign_in agent_user
    end

    it 'blocks unauthorized agent from managing assignment policies' do
      get assignment_policies_path(locale: :en)
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to eq(I18n.t('dashboard.authorization.not_authorized', default: 'You are not authorized to perform this action.'))
    end
  end
end
