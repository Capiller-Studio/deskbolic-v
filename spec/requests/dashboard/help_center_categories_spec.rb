# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::HelpCenter::Categories', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'help_center_portals' => true }, limits: { 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:domain) { create(:domain, account: account) }
  let!(:portal) { create(:help_center_portal, account: account, domain: domain, name: 'Main Help Center') }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /help_center/categories' do
    it 'renders categories index with categories' do
      create(:help_center_category, account: account, portal: portal, name: 'Billing')

      get help_center_categories_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Billing')
      expect(response.body).to include(I18n.t('dashboard.help_center.categories.index.title'))
    end
  end

  describe 'POST /help_center/categories' do
    it 'creates a category and redirects with success notice' do
      post help_center_categories_path(locale: :en), params: {
        category: {
          portal_id: portal.id,
          name: 'Getting Started',
          description: 'Guides to get you started quickly.',
          visibility: 'everyone'
        }
      }

      expect(response).to redirect_to(help_center_categories_path)
      expect(flash[:notice]).to eq('Category was successfully created.')

      created_category = account.with_shard do
        HelpCenter::Category.joins(:translations).where(help_center_category_translations: { name: 'Getting Started' }).first
      end
      expect(created_category).to be_present
    end

    it 'sets alert when name is blank' do
      post help_center_categories_path(locale: :en), params: {
        category: {
          portal_id: portal.id,
          name: ''
        }
      }

      expect(response).to redirect_to(help_center_categories_path)
      expect(flash[:alert]).to eq("Unable to create category: name can't be blank.")
    end
  end

  describe 'PATCH /help_center/categories/:id' do
    it 'updates a category and redirects with success notice' do
      category = create(:help_center_category, account: account, portal: portal, name: 'Old Name')

      patch help_center_category_path(id: category.id, locale: :en), params: {
        category: {
          name: 'New Category Name',
          description: 'Updated description'
        }
      }

      expect(response).to redirect_to(help_center_categories_path)
      expect(flash[:notice]).to eq('Category was successfully updated.')
      expect(account.with_shard { category.reload.name }).to eq('New Category Name')
    end
  end

  describe 'DELETE /help_center/categories/:id' do
    it 'destroys category and redirects with success notice' do
      category = create(:help_center_category, account: account, portal: portal, name: 'To Delete')

      delete help_center_category_path(id: category.id, locale: :en)

      expect(response).to redirect_to(help_center_categories_path)
      expect(flash[:notice]).to eq('Category was successfully deleted.')
      expect(account.with_shard { HelpCenter::Category.where(id: category.id) }).not_to exist
    end
  end

  describe 'GET /help_center/articles column selection' do
    it 'displays category column by default' do
      category = create(:help_center_category, account: account, portal: portal, name: 'Tutorials')
      create(:help_center_article, account: account, portal: portal, primary_category: category, title: 'First Steps')

      get help_center_articles_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tutorials')
      expect(response.body).to include('Category')
    end

    it 'filters columns when specific columns are requested' do
      category = create(:help_center_category, account: account, portal: portal, name: 'Tutorials')
      create(:help_center_article, account: account, portal: portal, primary_category: category, title: 'First Steps')

      get help_center_articles_path(locale: :en, columns: %w[title])

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('First Steps')
      expect(response.body).not_to include('hc-collection-cell')
    end
  end
end
