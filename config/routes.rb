# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  get "r/:referral_code", to: "affiliates#track", as: :referral

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
    get "new-role", to: "roles#new"



    resources :inbox, only: [ :index ]
    resources :conversations do
      get :append_conversation, on: :collection
      member do
        patch :snooz_conversation
        patch :close_conversation
        post  :assign_member
      end
    end
    resources :channels
    resources :inboxes
    resources :messages do
      get :append_message, on: :collection
    end
    resources :canned_responses
    resources :notes
    resources :teams
    resources :roles
    resources :custom_fields
    resources :field_resources, only: [:create, :destroy] do
      post :sort, on: :collection
    end
    get "custom_fields_builder/:resource_type/:resource_id", to: "custom_fields_builder#show", as: :custom_fields_builder

    namespace :help_center do
      resources :articles
    end

    resources :settings, only: [ :index ] do
      collection do
        get :canned_responses
        get :office_timings
        get :team_inboxes
        get :roles
        get :messenger
        get :teammates
        get :tickets
        get :people
      end
    end
    
    resources :custom_fields
    
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
