# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Channels', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) do
    create(:plan, features: { 'channels' => { 'email' => true, 'instagram' => true, 'whatsapp' => true, 'facebook' => true, 'contact_form' => true, 'web_widget' => true } }, limits: { 'channels' => 100, 'users' => 100 })
  end
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:email_channel) { account.with_shard { create(:channel_email, account: account, email: "test_#{SecureRandom.hex(4)}@acme.com") } }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'GET /channels/email' do
    it 'renders email channels index' do
      get channels_email_index_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /channels/email/new' do
    it 'renders new email channel form' do
      get new_channels_email_path(locale: :en)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /channels/email/:id' do
    it 'updates email channel name' do
      patch channels_email_path(id: email_channel.id, locale: :en), params: {
        email_channel: { name: 'Support New Name' }
      }
      expect(response).to have_http_status(:redirect)
      expect(account.with_shard { email_channel.reload.name }).to eq('Support New Name')
    end

    it 'retains existing smtp and imap passwords if submitted blank' do
      account.with_shard do
        email_channel.update!(
          smtp_enabled: true,
          imap_enabled: true,
          smtp_configurations: { 'address' => 'smtp.example.com', 'port' => 587, 'username' => 'u1', 'password' => 'secret_smtp_123' },
          imap_configurations: { 'address' => 'imap.example.com', 'port' => 993, 'username' => 'u1', 'password' => 'secret_imap_123' }
        )
      end

      patch channels_email_path(id: email_channel.id, locale: :en), params: {
        email_channel: {
          name: 'Updated Name',
          smtp_configurations: { address: 'smtp.new.com', port: '587', username: 'u1', password: '' },
          imap_configurations: { address: 'imap.new.com', port: '993', username: 'u1', password: '' }
        }
      }
      expect(response).to have_http_status(:redirect)
      account.with_shard do
        email_channel.reload
        expect(email_channel.smtp_configurations['address']).to eq('smtp.new.com')
        expect(email_channel.smtp_configurations['password']).to eq('secret_smtp_123')
        expect(email_channel.imap_configurations['address']).to eq('imap.new.com')
        expect(email_channel.imap_configurations['password']).to eq('secret_imap_123')
      end
    end
  end

    describe 'DELETE /channels/email/:id' do
      it 'destroys email channel' do
        delete channels_email_path(id: email_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { Channel::Email.where(id: email_channel.id) }).not_to exist
      end
    end

    describe 'POST /channels/email/:id/test_smtp' do
      let(:mock_smtp) { instance_double(Net::SMTP) }

      before do
        allow(Net::SMTP).to receive(:new).and_return(mock_smtp)
        allow(mock_smtp).to receive(:enable_starttls_auto)
        allow(mock_smtp).to receive(:open_timeout=)
        allow(mock_smtp).to receive(:read_timeout=)
      end

      it 'falls back to email domain when domain param is blank string' do
        expect(mock_smtp).to receive(:start).with(
          email_channel.email.split('@').last,
          'smtp_user',
          'secret',
          :plain
        ).and_yield(mock_smtp)

        post test_smtp_channels_email_path(id: email_channel.id, locale: :en), params: {
          email_channel: {
            email: email_channel.email,
            smtp_configurations: {
              address: 'smtp.example.com',
              port: 587,
              username: 'smtp_user',
              password: 'secret',
              domain: '',
              authentication: 'plain'
            }
          }
        }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to be true
      end
    end

  describe 'Facebook Pages Channels' do
    describe 'GET /channels/facebook/oauth_authorize' do
      it 'redirects to Meta dialog oauth URL with only approved scopes' do
        get oauth_authorize_channels_facebook_index_path(locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('https://www.facebook.com')
        expect(response.location).to include('dialog/oauth')
        expect(response.location).not_to include('pages_read_engagement')
        expect(response.location).to include('pages_show_list')
        expect(response.location).to include('pages_manage_metadata')
        expect(response.location).to include('pages_messaging')
      end

      context 'in production environment' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('DESKBOLIC_URL').and_return(nil)
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        end

        it 'uses the apex domain for redirect_uri' do
          get oauth_authorize_channels_facebook_index_path(locale: :en)
          expect(response).to have_http_status(:redirect)
          encoded_redirect = CGI.escape('https://deskbolic.app/channels/facebook/callback')
          expect(response.location).to include(encoded_redirect)
        end
      end
    end

    describe 'GET /channels/facebook/callback' do
      let(:secret) { 'test_secret' }
      let(:state_token) do
        JWT.encode({ sub: account.id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, secret, 'HS256')
      end

      before do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :facebook, :app_secret).and_return(secret)
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :facebook, :app_id).and_return('fb_app_123')
      end

      context 'when accessed on apex domain' do
        before { set_subdomain(nil) }

        it 'redirects to the tenant subdomain callback' do
          get channels_facebook_callback_path(code: 'test_code', state: state_token)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include(account.identifier)
          expect(response.location).to include('test_code')
        end
      end

      context 'when accessed on tenant subdomain' do
        before do
          allow(Channels::FacebookPages::TokenExchangeService).to receive(:call).and_return({
            user_access_token: 'user_token',
            pages: [
              { id: 'page_123', name: 'My Page', access_token: 'page_token', category: 'Business', avatar_url: nil, already_connected: false }
            ]
          })
        end

        it 'exchanges the code and renders page selection' do
          get callback_channels_facebook_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('My Page')
        end
      end
    end
  end

  describe 'WhatsApp Channels' do
    let(:phone_suffix) { SecureRandom.random_number(1000000..9999999).to_s }
    let(:whatsapp_channel) do
      account.with_shard do
        create(:channel_whatsapp, account: account, name: 'Support WhatsApp', full_phone_number: "+1555#{phone_suffix}", phone_number_id: "phone_#{phone_suffix}", business_account_id: "waba_#{phone_suffix}")
      end
    end

    describe 'GET /channels/whatsapp' do
      it 'renders whatsapp channels index' do
        get channels_whatsapp_index_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/whatsapp/new' do
      it 'renders new whatsapp channel form' do
        get new_channels_whatsapp_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/whatsapp/oauth_authorize' do
      it 'redirects to Meta dialog oauth URL' do
        get oauth_authorize_channels_whatsapp_index_path(locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('https://www.facebook.com')
        expect(response.location).to include('dialog/oauth')
      end

      context 'in production environment' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('DESKBOLIC_URL').and_return(nil)
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        end

        it 'uses the apex domain for redirect_uri' do
          get oauth_authorize_channels_whatsapp_index_path(locale: :en)
          expect(response).to have_http_status(:redirect)
          encoded_redirect = CGI.escape('https://deskbolic.app/channels/whatsapp/callback')
          expect(response.location).to include(encoded_redirect)
        end
      end
    end

    describe 'GET /channels/whatsapp/callback' do
      let(:secret) { 'test_secret' }
      let(:state_token) do
        JWT.encode({ sub: account.id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, secret, 'HS256')
      end

      before do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_secret).and_return(secret)
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :whatsapp, :app_id).and_return('wa_app_123')
      end

      context 'when accessed on apex domain' do
        before { set_subdomain(nil) }

        it 'redirects to the tenant subdomain callback' do
          get channels_whatsapp_callback_path(code: 'test_code', state: state_token)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include(account.identifier)
          expect(response.location).to include('test_code')
        end
      end

      context 'when accessed on tenant subdomain' do
        let(:cb_phone) { "+1 555-#{SecureRandom.random_number(100..999)}-#{SecureRandom.random_number(1000..9999)}" }
        let(:cb_phone_id) { "phone_#{SecureRandom.hex(4)}" }
        let(:cb_waba_id) { "waba_#{SecureRandom.hex(4)}" }

        before do
          allow(Channels::Whatsapp::SignupService).to receive(:call).and_return({
            access_token: 'meta_access_token',
            waba_id: cb_waba_id,
            phone_number_id: cb_phone_id,
            display_phone_number: cb_phone,
            name: 'Techbolic Live Support'
          })
        end

        it 'exchanges the code, creates the channel, and redirects to edit' do
          get callback_channels_whatsapp_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:see_other)
          expect(account.with_shard { Channel::Whatsapp.where(phone_number_id: cb_phone_id) }).to exist
        end
      end
    end

    describe 'POST /channels/whatsapp/callback' do
      let(:cb_phone) { "+1 555-#{SecureRandom.random_number(100..999)}-#{SecureRandom.random_number(1000..9999)}" }
      let(:cb_phone_id) { "phone_#{SecureRandom.hex(4)}" }
      let(:cb_waba_id) { "waba_#{SecureRandom.hex(4)}" }

      before do
        allow(Channels::Whatsapp::SignupService).to receive(:call).with(
          hash_including(
            code: 'valid_auth_code',
            waba_id: cb_waba_id,
            phone_number_id: cb_phone_id,
            account: account
          )
        ).and_return({
          access_token: 'meta_access_token',
          waba_id: cb_waba_id,
          phone_number_id: cb_phone_id,
          display_phone_number: cb_phone,
          name: 'Techbolic Live Support'
        })
      end

      it 'completes embedded signup and redirects to edit' do
        post callback_channels_whatsapp_index_path(locale: :en), params: {
          code: 'valid_auth_code',
          waba_id: cb_waba_id,
          phone_number_id: cb_phone_id
        }
        expect(response).to have_http_status(:see_other)
        expect(account.with_shard { Channel::Whatsapp.where(phone_number_id: cb_phone_id) }).to exist
      end

      it 'handles SignupService errors gracefully and redirects to new' do
        allow(Channels::Whatsapp::SignupService).to receive(:call).and_raise(RuntimeError.new('Invalid OAuth Code'))

        post callback_channels_whatsapp_index_path(locale: :en), params: { code: 'bad_code' }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_channels_whatsapp_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('dashboard.whatsapp_channels.callback_error'))
      end

      it 'redirects if channel limit is reached' do
        plan.update!(limits: { 'channels' => 0, 'users' => 100 })

        post callback_channels_whatsapp_index_path(locale: :en), params: {
          code: 'valid_auth_code',
          waba_id: cb_waba_id,
          phone_number_id: cb_phone_id
        }
        expect(response).to have_http_status(:redirect)
      end
    end

    describe 'POST /channels/whatsapp (Manual setup)' do
      let(:manual_suffix) { SecureRandom.random_number(1000000..9999999).to_s }
      let(:valid_params) do
        {
          channel_whatsapp: {
            name: 'Manual WhatsApp',
            phone_code: '+1',
            phone_number: "555#{manual_suffix}",
            phone_number_id: "phone_manual_#{manual_suffix}",
            business_account_id: "waba_manual_#{manual_suffix}",
            api_key: 'permanent_token_123'
          }
        }
      end

      it 'creates a new manual WhatsApp channel and redirects to edit' do
        post channels_whatsapp_index_path(locale: :en), params: valid_params
        expect(response).to have_http_status(:see_other)
        expect(account.with_shard { Channel::Whatsapp.where(phone_number_id: "phone_manual_#{manual_suffix}") }).to exist
      end

      it 'handles invalid parameters by redirecting to new form' do
        post channels_whatsapp_index_path(locale: :en), params: {
          channel_whatsapp: { name: '', phone_number: '' }
        }
        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(new_channels_whatsapp_path)
      end
    end

    describe 'PATCH /channels/whatsapp/:id' do
      it 'updates channel name' do
        patch channels_whatsapp_path(id: whatsapp_channel.id, locale: :en), params: {
          channel_whatsapp: { name: 'Updated Channel Name' }
        }
        expect(response).to have_http_status(:see_other)
        expect(account.with_shard { whatsapp_channel.reload.name }).to eq('Updated Channel Name')
      end

      it 'retains existing api_key if submitted blank' do
        account.with_shard { whatsapp_channel.update!(api_key: 'original_token_xyz') }

        patch channels_whatsapp_path(id: whatsapp_channel.id, locale: :en), params: {
          channel_whatsapp: { name: 'New Name', api_key: '' }
        }
        expect(response).to have_http_status(:see_other)
        account.with_shard do
          whatsapp_channel.reload
          expect(whatsapp_channel.name).to eq('New Name')
          expect(whatsapp_channel.api_key).to eq('original_token_xyz')
        end
      end
    end

    describe 'DELETE /channels/whatsapp/:id' do
      it 'destroys whatsapp channel' do
        delete channels_whatsapp_path(id: whatsapp_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { Channel::Whatsapp.where(id: whatsapp_channel.id) }).not_to exist
      end
    end
  end

  describe 'Instagram Channels' do
    let(:instagram_channel) do
      account.with_shard do
        create(:channel_instagram, account: account, name: 'Main Instagram', instagram_id: "ig_#{SecureRandom.hex(4)}")
      end
    end

    describe 'GET /channels/instagram' do
      it 'renders instagram channels index' do
        get channels_instagram_index_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/instagram/new' do
      it 'renders new instagram channel form' do
        get new_channels_instagram_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/instagram/oauth_authorize' do
      it 'redirects to Instagram OAuth authorize URL' do
        get oauth_authorize_channels_instagram_index_path
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('https://www.instagram.com/oauth/authorize')
        expect(response.location).to include('client_id=')
        expect(response.location).to include('response_type=code')
        expect(response.location).to include('instagram_business_basic')
      end
    end

    describe 'GET /channels/instagram/callback' do
      let(:secret) { 'test_secret' }
      let(:state_token) do
        JWT.encode({ sub: account.id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, secret, 'HS256')
      end

      before do
        allow(Rails.application.credentials).to receive(:dig).with(:channels, :instagram, :app_secret).and_return(secret)
      end

      context 'when accessed on apex domain' do
        before { set_subdomain(nil) }

        it 'redirects to the tenant subdomain callback' do
          get channels_instagram_callback_path(code: 'test_code', state: state_token)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include(account.identifier)
          expect(response.location).to include('test_code')
        end
      end

      context 'when accessed on tenant subdomain' do
        let(:oauth_service) { instance_double(Channels::Instagram::OauthService) }

        before do
          allow(Channels::Instagram::OauthService).to receive(:new).with(account: account).and_return(oauth_service)
          allow(oauth_service).to receive(:exchange_code).and_return({
            access_token: 'ig_long_lived_token',
            expires_at: 60.days.from_now,
            user: { id: '987654321', username: 'acme_ig', name: 'Acme IG', avatar_url: 'https://example.com/avatar.jpg' }
          })
        end

        it 'exchanges the code, creates the channel, and redirects to edit' do
          get callback_channels_instagram_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:redirect)
          expect(account.with_shard { Channel::Instagram.where(instagram_id: '987654321') }).to exist
        end

        it 'updates and reactivates existing channel if already connected' do
          reconnect_ig_id = "reconnect_ig_#{SecureRandom.hex(4)}"
          existing = account.with_shard do
            create(:channel_instagram, account: account, instagram_id: reconnect_ig_id, status: :disconnected)
          end

          allow(oauth_service).to receive(:exchange_code).and_return({
            access_token: 'ig_reconnected_token',
            expires_at: 60.days.from_now,
            user: { id: reconnect_ig_id, username: 'acme_ig', name: 'Acme IG', avatar_url: 'https://example.com/avatar.jpg' }
          })

          get callback_channels_instagram_index_path(code: 'test_code', state: state_token, locale: :en)
          expect(response).to have_http_status(:redirect)
          expect(existing.reload.status).to eq('active')
          expect(existing.access_token).to eq('ig_reconnected_token')
        end
      end
    end

    describe 'PATCH /channels/instagram/:id' do
      it 'updates instagram channel name' do
        patch channels_instagram_path(id: instagram_channel.id, locale: :en), params: {
          instagram_channel: { name: 'Updated Instagram Name' }
        }
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { instagram_channel.reload.name }).to eq('Updated Instagram Name')
      end
    end

    describe 'DELETE /channels/instagram/:id' do
      it 'destroys instagram channel' do
        delete channels_instagram_path(id: instagram_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { Channel::Instagram.where(id: instagram_channel.id) }).not_to exist
      end
    end
  end

  describe 'Contact Form Channels' do
    let(:contact_form_channel) do
      account.with_shard do
        channel = create(:channel_contact_form, account: account, name: 'Main Contact Form')
        create(:inbox, channel: channel, account: account, primary_inbox: true)
        channel
      end
    end

    describe 'GET /channels/contact_form' do
      it 'renders contact form channels index' do
        get channels_contact_form_index_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /channels/contact_form/new' do
      it 'renders new contact form channel form' do
        get new_channels_contact_form_path(locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST /channels/contact_form' do
      it 'creates a contact form channel and redirects to edit' do
        expect {
          post channels_contact_form_index_path(locale: :en), params: {
            contact_form_channel: {
              name: 'Support Request Form',
              allow_attachments: '1',
              send_confirmation_email: '1',
              spam_protection_enabled: '1'
            }
          }
          expect(response).to have_http_status(:redirect)
        }.to change { account.with_shard { Channel::ContactForm.count } }.by(1)
      end
    end

    describe 'GET /channels/contact_form/:id' do
      it 'renders show details page with embed instructions' do
        get channels_contact_form_path(id: contact_form_channel.id, locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(contact_form_channel.name)
      end
    end

    describe 'GET /channels/contact_form/:id/edit' do
      it 'renders edit contact form channel page' do
        get edit_channels_contact_form_path(id: contact_form_channel.id, locale: :en)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH /channels/contact_form/:id' do
      it 'updates contact form channel name, flags, and custom CSS in ui_configurations' do
        patch channels_contact_form_path(id: contact_form_channel.id, locale: :en), params: {
          contact_form_channel: {
            name: 'Updated Contact Form Name',
            require_login: '1',
            allow_attachments: '0',
            send_confirmation_email: '1',
            spam_protection_enabled: '1',
            ui_configurations: {
              theme_color: '#3b82f6',
              position: 'center',
              custom_css: '.contact-form-title { color: #1e293b; }'
            }
          }
        }
        expect(response).to have_http_status(:redirect)

        account.with_shard do
          contact_form_channel.reload
          expect(contact_form_channel.name).to eq('Updated Contact Form Name')
          expect(contact_form_channel.require_login?).to be true
          expect(contact_form_channel.allow_attachments?).to be false
          expect(contact_form_channel.send_confirmation_email?).to be true
          expect(contact_form_channel.spam_protection_enabled?).to be true
          expect(contact_form_channel.custom_css).to eq('.contact-form-title { color: #1e293b; }')
          expect(contact_form_channel.ui_configurations['theme_color']).to eq('#3b82f6')
        end
      end

      it 'handles ordered_fields and primary_inbox collaborator params without error' do
        inbox = account.with_shard { contact_form_channel.primary_inbox }
        other_user = create(:user)
        account.with_shard { create(:account_user, account: account, user: other_user) }

        patch channels_contact_form_path(id: contact_form_channel.id, locale: :en), params: {
          contact_form_channel: {
            name: 'Form with Collaborators',
            ordered_fields: [ "non-existent-field-id" ],
            primary_inbox_attributes: {
              id: inbox.id,
              user_ids: [ user.id.to_s, other_user.id.to_s ]
            },
            ui_configurations: {
              theme_color: "#7C3AED"
            }
          }
        }
        expect(response).to have_http_status(:redirect)

        account.with_shard do
          contact_form_channel.reload
          expect(contact_form_channel.name).to eq("Form with Collaborators")
          expect(contact_form_channel.ui_configurations["theme_color"]).to eq("#7C3AED")
          expect(inbox.reload.assigned_user_ids).to contain_exactly(user.id.to_s, other_user.id.to_s)
        end
      end
    end

    describe 'DELETE /channels/contact_form/:id' do
      it 'destroys contact form channel' do
        delete channels_contact_form_path(id: contact_form_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(account.with_shard { Channel::ContactForm.where(id: contact_form_channel.id) }).not_to exist
      end
    end

    describe 'POST /channels/contact_form/:id/purge_cache' do
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        memory_store.clear
      end

      it 'purges CDN cache and throttles spamming attempts' do
        allow(Cloudflare::PurgeService).to receive(:purge_contact_form).with(contact_form_channel).and_return({ success: true, purged: 9 })

        post purge_cache_channels_contact_form_path(id: contact_form_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present

        # Second attempt within cooldown window is throttled
        post purge_cache_channels_contact_form_path(id: contact_form_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include('Please wait a moment before purging the cache again')
      end
    end

    describe 'POST /channels/web_widget/:id/purge_cache' do
      let(:web_widget_channel) { account.with_shard { create(:channel_web_widget, account: account) } }
      let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        memory_store.clear
      end

      it 'purges WebWidget CDN cache and throttles spamming attempts' do
        allow(Cloudflare::PurgeService).to receive(:purge_web_widget).with(web_widget_channel).and_return({ success: true, purged: 9 })

        post purge_cache_channels_web_widget_path(id: web_widget_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present

        # Second attempt within cooldown window is throttled
        post purge_cache_channels_web_widget_path(id: web_widget_channel.id, locale: :en)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include('Please wait a moment before purging the cache again')
      end
    end

    describe 'GET /channels/web_widget/new' do
      it 'renders new web widget form with tabbed translations UI and proper icons' do
        get new_channels_web_widget_path(locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('ui-locale-editor')
        expect(response.body).to include('ui-locale-tabs')
        expect(response.body).to include('ui-locale-panels')
        # Does not leak raw languages hash into header
        expect(response.body).not_to include('{:en=&gt;&quot;English&quot;')
        expect(response.body).not_to include('{en: &quot;English&quot;')
        # Inlined translation icon path (M12.87 15.07 from translate.svg)
        expect(response.body).to include('M12.87 15.07')
        # Inlined dropdown chevron path (M12.6673 6L8.00065 from dropdown.svg)
        expect(response.body).to include('M12.6673 6')
      end
    end

    describe 'GET /channels/web_widget/:id/edit' do
      let(:web_widget_channel) { account.with_shard { create(:channel_web_widget, account: account) } }

      it 'renders edit web widget form with tabbed translations and dropdown chevron in installation section' do
        get edit_channels_web_widget_path(id: web_widget_channel.id, locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('ui-locale-editor')
        expect(response.body).to include('data-web-widget-channel-target="installationSection"')
        expect(response.body).not_to include('▼')
      end
    end

    describe 'GET /channels/contact_form/new' do
      it 'renders contact form with clean form_fields.svg, translate.svg and dropdown chevrons' do
        get new_channels_contact_form_path(locale: :en)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('ui-locale-editor')
        # Inlined form_fields.svg (rect and field lines)
        expect(response.body).to include('x="2.5" y="2.5" width="15" height="15"')
        # Inlined translate.svg path
        expect(response.body).to include('M12.87 15.07')
        # Inlined dropdown chevron and no unicode ▼
        expect(response.body).to include('M12.6673 6')
        expect(response.body).not_to include('span class="ww-section-chevron">▼')
      end
    end
  end
end
