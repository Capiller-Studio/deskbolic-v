# frozen_string_literal: true

require_relative "../lib/subdomain_constraint"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # TODO: remove later, this route is just for testing indentity sources module in development.
  if Rails.env.development?
    match "test_api/identity_endpoint", to: "test_api#identity_endpoint", via: [ :get, :post ]
    match "test_api/custom_channel_endpoint", to: "test_api#custom_channel_endpoint", via: [ :get, :post ]
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # TODO: Change route
  mount Facebook::Messenger::Server, at: "webhooks/facebook"

  namespace :webhooks do
    get "whatsapp/:account_id/:channel_id", to: "whatsapp#hub"
    post "whatsapp/:account_id/:channel_id", to: "whatsapp#index"

    post "custom/:account_id/:channel_id", to: "custom#create"

    get "whatsapp", to: "whatsapp#hub"
    post "whatsapp", to: "whatsapp#index"

    get "widget/:account_id/:channel_id", to: "widget#hub"
    post "widget/:account_id/:channel_id", to: "widget#index"

    get "instagram", to: "instagram#hub"
    post "instagram", to: "instagram#index"

    namespace :sms do
      post "twilio/:account_id/:channel_id", to: "twilio#create"
      post "signalwire/:account_id/:channel_id", to: "signalwire#create"
      post "aws_sns/:account_id/:channel_id", to: "aws_sns#create"
    end

    post "paddle", to: "paddle#create"
    post "stripe", to: "stripe#create"
  end

  # NOTE on Devise Route Architecture:
  # Devise is declared twice using :only and :skip options:
  # 1. External OAuth Providers (Google, Facebook) require static, deterministic callback URIs
  #    (e.g., /users/auth/google_oauth2/callback) without variable locale segments (/en/, /es/).
  #    Therefore, omniauth_callbacks is mounted at the root level outside any locale scope.
  # 2. User-facing sessions, registrations, confirmations, and password screens live inside
  #    scope "(:locale)" to support internationalization, with omniauth_callbacks explicitly skipped.
  # This pattern generates zero route collisions and avoids invalid locale redirect loops.
  devise_for :users, only: :omniauth_callbacks, controllers: {
    omniauth_callbacks: "dashboard/omniauth_callbacks"
  }

  scope "(:locale)", locale: /#{Core::SUPPORTED_LOCALES.join('|')}|[a-z]{2}(?:-[A-Za-z]{2,4})?|invalid_[a-zA-Z0-9_]+/ do
    devise_for :users, path: "",
    path_names: { sign_in: "login", sign_out: "logout", sign_up: "register" },
    skip: :omniauth_callbacks,
    controllers: {
      registrations: "dashboard/registrations",
      sessions: "dashboard/sessions",
      confirmations: "dashboard/confirmations",
      unlocks: "dashboard/unlocks",
      passwords: "dashboard/passwords"
    }

    devise_scope :user do
      get "registered", to: "dashboard/registrations#registered", as: :registered
    end

    # Unified Authentication & SSO Endpoints
    namespace :auth do
      get "check_email", to: "validations#check_email"
      get "check_identifier", to: "validations#check_identifier"
      get "domain_lookup", to: "domain_lookups#show"

      namespace :saml do
        get  "metadata", to: "sessions#metadata"
        get  "initiate", to: "sessions#initiate"
        post "consume",  to: "sessions#consume"
      end
    end

    scope module: "dashboard" do
      root "conversations#index"

      get "workspaces", to: "workspace#index", as: :workspaces
      get "workspace", to: "workspace#new", as: :workspace
      post "workspace", to: "workspace#create"
      get "workspaces/:id/submitted", to: "workspace#submitted", as: "submitted"
    # Removed: post "facebook_page", to: "facebook_page#index"  — replaced by facebook_channels resource below
    get "terms", to: "pages#service_terms"
    get "help-center", to: "pages#help_center"
    get "community", to: "pages#community_forum"
    get "invite/:token", to: "account_invitations#email_invitation", as: :invite
    post "invite/:token", to: "account_invitations#accept_invitation", as: :accept_invite
    get "profile", to: "profile#index"
    patch "profile", to: "profile#update"
    delete "profile", to: "profile#destroy"
    namespace :channels do
      get "instagram/callback", to: "instagram#callback"
      get "whatsapp/callback", to: "whatsapp#callback"
      get "facebook/callback", to: "facebook#callback"
    end
    get "integrations/slack/callback", to: "integrations#slack_callback"

    constraints(SubdomainConstraint) do
      resources :search, only: [ :index ], controller: "searches" do
        get :suggestions, on: :collection
      end
      resources :inbox, only: [ :index ]
      resources :conversations do
        resources :canned_responses, only: [ :index ], module: :conversations
        get :append_conversation, on: :collection
        get :reorder_conversation, on: :collection
        member do
          patch :snooz_conversation
          patch :close_conversation
          patch :mark_as_read
          post  :assign_member
          post  :unassign_member
          post  :assign_team
          post  :unassign_team
          post  :add_label
          delete :remove_label
        end
        resources :messages, only: [ :index ]

        resource :ai, only: [], controller: "conversations/ai" do
          post :summarize
          post :draft_reply
          post :rewrite_tone
          post :fix_grammar
          post :translate
        end
      end
      namespace :channels do
        resources :email do
          member do
            post :test_smtp
            post :test_imap
            post :verify_forwarding
          end
        end

        resources :web_widget do
          member do
            post :purge_cache
          end
        end
        resources :mobile_widget do
          member do
            post :regenerate_secret
            post :test_push
          end
        end
        resources :contact_form do
          member do
            post :purge_cache
          end
        end

        resources :facebook do
          member do
            post :reconnect
          end
          collection do
            get :oauth_authorize
            get :callback
            post :callback
          end
        end

        resources :instagram do
          collection do
            get :oauth_authorize
            get :callback
          end
        end

        resources :whatsapp do
          member do
            post :reconnect
            post :sync_templates
          end
          collection do
            get :oauth_authorize
            get :callback
            post :callback
          end
        end

        resources :custom do
          member do
            post :test_outgoing_webhook
            post :test_incoming_webhook
          end
        end
      end

      resources :channels
      resources :reports, only: [ :index ]
      resources :inboxes do
        member do
          post :add_member
          delete :remove_member
          patch :update_members
        end
      end
      resources :messages do
        get :append_message, on: :collection
        get :update_message, on: :collection
        post :translate, on: :member
      end
      resources :activities, only: [] do
        get :append_activity, on: :collection
      end
      resources :canned_responses
      resources :labels
      resources :ai_agents
      resources :notes
      resources :teams do
        member do
          post :add_member
          delete :remove_member
        end
      end
      resources :roles
      resources :users, controller: "account_users", except: [ :show ] do
        get :search, on: :collection
      end
      resources :customers, only: [ :index, :show, :edit, :update ]
      resources :invitations, controller: "account_invitations", except: [ :show ]
      resources :custom_fields
      resources :assignment_policies do
        member do
          patch :toggle
        end
        collection do
          patch :reorder
        end
      end
      resources :sla_policies do
        collection do
          patch :reorder
        end
      end
      resources :business_hour_groups, path: "business_hours"
      resources :skills, except: [ :show ]
      resources :field_resources, only: [ :create, :destroy ] do
        post :sort, on: :collection
      end
      get "custom_fields_builder/:resource_type/:resource_id", to: "custom_fields_builder#show", as: :custom_fields_builder

      resources :domains do
        member do
          post :verify_dns
        end
      end

      namespace :help_center do
        resources :portals, only: [ :index, :new, :create, :edit, :update ]
        resources :articles do
          member do
            post :publish
            post :discard_draft
            post :copy_locale
          end
          collection do
            patch :reorder
          end
        end
        resources :categories, only: %i[index create update destroy]
      end

      resources :automations do
        member do
          patch :toggle
          post :duplicate
        end
        collection do
          patch :reorder
          get :lookups
        end
      end
      resources :macros, except: [ :show ] do
        member do
          post :execute
          patch :toggle
        end
        collection do
          get :available
        end
      end
      resources :automation_executions, only: [ :index ]

      resource :billing, only: [ :show ], as: :dashboard_billing do
        post :dismiss_warning
      end
      resources :subscriptions, only: [ :new, :create, :update ] do
        member do
          post :cancel
          post :resume
        end
      end
      resources :payment_methods, only: [ :new, :create, :destroy ] do
        member do
          post :make_default
        end
        collection do
          get :setup_intent
        end
      end
      resource :wallet, only: [] do
        post :topup
      end
      resources :ai_credits, only: [ :create ]

      resources :settings, only: [ :index ]

      namespace :settings do
        resource :general, only: [ :show, :update, :destroy ], controller: "general"
        resource :notifications, only: [ :show, :edit, :update ], controller: "notification_settings"
        resources :notification_subscriptions, only: [ :create, :destroy ]
        resources :audit_logs, only: [ :index ] do
          member do
            post :revert
          end
        end
        resources :api_keys, only: [ :index, :create, :destroy ]
        resource :sso, only: [ :show, :update ], controller: "sso"
        resources :domain_verifications, only: [ :index, :create, :destroy ] do
          member do
            post :verify
          end
        end
        resources :scim_tokens, only: [ :index, :create, :destroy ]
      end

      resources :notifications, only: [ :index ] do
        collection do
          post :mark_all_read
          get :update_badge
        end
        member do
          post :mark_read
        end
      end

      resources :identity_sources, except: [ :show ] do
        collection do
          match :test_connection, via: [ :post, :patch ]
        end
      end

      resources :integrations, except: [ :show ] do
        collection do
          get "slack/oauth_authorize", to: "integrations#oauth_authorize_slack"
          get "slack/callback", to: "integrations#slack_callback"
          post "slack/test", to: "integrations#test_slack"
        end
      end

      resources :email_templates, only: [ :index, :new, :create, :edit, :update, :destroy ] do
        member do
          post :publish
          post :discard_draft
          get :preview
          post :send_test
          get :variables
          post :copy_locale
        end
      end

      resources :csat_surveys

      resources :email_template_layouts, only: [ :index, :edit, :update ] do
        member do
          post :publish
          post :discard_draft
          get :preview
          post :copy_locale
        end
      end

      resources :attachments, only: [ :show, :create, :destroy ]
      resources :agent, only: [ :index ] do
        collection do
          get :test
          get :fin_test
          get :guidance
          get :task
          get :workflow
          get :topics
        end
      end

        get "popup/:step", to: "popup#modal_popup"
      end
    end
  end

  # SCIM 2.0 Directory Sync API (RFC 7643 / 7644)
  namespace :api do
    namespace :scim do
      namespace :v2 do
        # RFC 7643 Discovery Endpoints (public — no auth required)
        resource :service_provider_config, only: [ :show ], controller: "service_provider_config"
        resources :resource_types, only: [ :index, :show ]
        resources :schemas, only: [ :index, :show ], constraints: { id: /[^\/]+/ }

        # RFC 7644 Resource Endpoints (Bearer token auth required)
        resources :users, only: [ :index, :show, :create, :update, :destroy ]
        resources :groups, only: [ :index, :show, :create, :update, :destroy ]
      end
    end
  end
end
