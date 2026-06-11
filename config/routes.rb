# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # TOOD: Not needed here, it's part of marketing app
  get "r/:referral_code", to: "affiliates#track", as: :referral

  # TODO: remove later, this route is just for testing indentity sources module in development.
  if Rails.env.development?
    match "test_api/identity_endpoint", to: "test_api#identity_endpoint", via: [:get, :post]
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # TODO: Change route
  mount Facebook::Messenger::Server, at: "webhooks/facebook"

  namespace :webhooks do
    get "whatsapp/:account_id/:channel_id", to: "whatsapp#hub"
    post "whatsapp/:account_id/:channel_id", to: "whatsapp#index"
    
    get "widget/:account_id/:channel_id", to: "widget#hub"
    post "widget/:account_id/:channel_id", to: "widget#index"

    namespace :sms do
      post "twilio/:account_id/:channel_id", to: "twilio#create"
      post "signalwire/:account_id/:channel_id", to: "signalwire#create"
      post "aws_sns/:account_id/:channel_id", to: "aws_sns#create"
    end

    post "paddle", to: "paddle#create"
    post "stripe", to: "stripe#create"
  end

  scope "(:locale)", locale: /#{Core::SUPPORTED_LOCALES.join('|')}/ do
    devise_for :users, path: "",
    path_names: { sign_in: "login", sign_out: "logout", sign_up: "register" },
    controllers: {
      registrations: "dashboard/registrations",
      sessions: "dashboard/sessions",
      confirmations: "dashboard/confirmations",
      unlocks: "dashboard/unlocks",
      passwords: "dashboard/passwords"
    }

    devise_scope :user do
      post "sessions/switch/:id", to: "dashboard/sessions#switch", as: :switch_account
      get "users/check_email", to: "dashboard/registrations#check_email"
      get "registered", to: "dashboard/registrations#registered", as: :registered
    end

    scope module: "dashboard" do
      root "channels#index"

    get "workspace", to: "workspace#new"
    post "workspace", to: "workspace#create"
    get "workspaces/:id/submitted", to: "workspace#submitted", as: "submitted"
    post :switch, to: "sessions#switch"
    post "facebook_page", to: "facebook_page#index"
    get "terms", to: "pages#service_terms"
    get "help-center", to: "pages#help_center"
    get "community", to: "pages#community_forum"
    get "email-invitation", to: "workspace#email_invitation"



    resources :inbox, only: [ :index ]
    resources :conversations do
      get :append_conversation, on: :collection
      member do
        patch :snooz_conversation
        patch :close_conversation
        post  :assign_member
        post  :assign_team
        post  :unassign_team
      end
    end
    resources :channels
    resources :inboxes
    resources :messages do
      get :append_message, on: :collection
    end
    resources :canned_responses
    resources :notes
    resources :teams do
      member do
        post :add_member
        delete :remove_member
      end
    end
    resources :roles
    resources :users, controller: "account_users", except: [:show]
    resources :invitations, controller: "account_invitations", except: [:show]
    resources :teams
    resources :custom_fields
    resources :assignment_policies do
      member do
        patch :toggle
      end
      collection do
        patch :reorder
      end
    end
    resources :skills, except: [:show]
    resources :field_resources, only: [:create, :destroy] do
      post :sort, on: :collection
    end
    get "custom_fields_builder/:resource_type/:resource_id", to: "custom_fields_builder#show", as: :custom_fields_builder

    resources :domains do
      member do
        post :verify_dns
      end
    end

    namespace :help_center do
      resources :articles do
        member do
          post :publish
          post :discard_draft
          post :copy_locale
        end
      end
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
    resources :macros, except: [:show] do
      member do
        post :execute
      end
    end
    resources :automation_executions, only: [:index]

    resource :billing, only: [:show], as: :dashboard_billing do
      post :dismiss_warning
    end
    resources :subscriptions, only: [:new, :create, :update] do
      member do
        post :cancel
        post :resume
      end
    end
    resources :payment_methods, only: [:new, :create, :destroy] do
      collection do
        get :setup_intent
      end
    end
    resource :wallet, only: [] do
      post :topup
    end

    resources :settings, only: [ :index ] do
      collection do
        get :canned_responses
        get :office_timings
        get :team_inboxes
        get :messenger
        get :teammates
        get :tickets
        get :people
      end
    end
    
    resources :identity_sources, except: [:show] do
      collection do
        match :test_connection, via: [:post, :patch]
      end
    end

    resources :email_channels, except: [:show] do
      member do
        post :test_smtp
        post :test_imap
        post :verify_forwarding
      end
    end
    
    resources :web_widget_channels, except: [:show]
    resources :contact_form_channels, except: [:show]
    
    resources :custom_fields

    resources :email_templates, only: [:index, :new, :create, :edit, :update, :destroy] do
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

    resources :email_template_layouts, only: [:index, :edit, :update] do
      member do
        post :publish
        post :discard_draft
        get :preview
        post :copy_locale
      end
    end

    resources :attachments, only: [:show, :create, :destroy]
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
