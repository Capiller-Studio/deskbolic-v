# frozen_string_literal: true

module Api
  module Internal
    module V1
      class ProvisionsController < ApplicationController
        skip_before_action :verify_authenticity_token
        skip_before_action :persist_onboarding_params

        def create
          return unless authorized?

          email = params[:email].to_s.strip.downcase
          password = params[:password].to_s
          name = params[:name].to_s.strip
          workspace_name = params[:workspace_name].to_s.strip
          plan_name = params[:plan].to_s.strip

          if email.blank? || password.blank? || name.blank? || workspace_name.blank? || plan_name.blank?
            return render(json: { success: false, error: "email, password, name, workspace_name, and plan are required" }, status: :unprocessable_entity)
          end

          plan = find_plan(plan_name)
          if plan.nil?
            return render(json: { success: false, error: "Unknown plan" }, status: :unprocessable_entity)
          end

          user, account = provision!(email:, password:, name:, workspace_name:, plan:)

          render(json: {
            success: true,
            user_id: user.id,
            account_id: account.id,
            login_url: CapillerHost.login_url
          })
        rescue ActiveRecord::RecordInvalid => error
          render(json: { success: false, error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity)
        end

        private

        def authorized?
          expected = ENV["CAPILLER_INTERNAL_SECRET"].to_s
          if expected.blank?
            render(json: { success: false, error: "Provisioning is not configured" }, status: :service_unavailable)
            return false
          end

          provided = request.headers["X-Capiller-Internal-Secret"].to_s
          return true if provided.bytesize == expected.bytesize && ActiveSupport::SecurityUtils.secure_compare(provided, expected)

          render(json: { success: false, error: "Unauthorized" }, status: :unauthorized)
          false
        end

        def find_plan(plan_name)
          plans = Plan.where("LOWER(name) = ?", plan_name.downcase)
          plans.find_by(currency: "INR") || plans.first
        end

        def provision!(email:, password:, name:, workspace_name:, plan:)
          ActiveRecord::Base.transaction do
            user = upsert_user!(email:, password:, name:)
            account = user.accounts.find_by(name: workspace_name) || create_account!(user:, workspace_name:)
            ensure_subscription!(account:, plan:)
            [ user, account ]
          end
        end

        def upsert_user!(email:, password:, name:)
          user = User.find_or_initialize_by(email: email)
          return user if user.persisted?

          first_name, last_name = name.split(/\s+/, 2)
          user.first_name = first_name
          user.last_name = last_name if last_name.present?
          user.password = password
          user.address ||= Address.create!
          user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
          user.confirmed_at ||= Time.current
          user.save!
          user
        end

        def create_account!(user:, workspace_name:)
          account = Account.create!(
            name: workspace_name,
            email: user.email,
            currency: "INR",
            shard_key: "de",
            locale: "en",
            timezone: "UTC",
            address: Address.create!
          )
          account_user = account.account_users.create!(user: user, owner: true)
          account.with_shard do
            owner_role = account.roles.find_by!(identifier: "owner")
            Access::AccountUserRole.create!(
              account: account,
              account_user: account_user,
              role: owner_role
            )
          end
          account
        end

        def ensure_subscription!(account:, plan:)
          return if account.subscriptions.where(status: [ :active, :trialing ]).exists?

          Subscription.create!(
            account: account,
            plan: plan,
            status: :active,
            billing_cycle: :monthly,
            quantity: [ plan.min_users, 1 ].max,
            currency: plan.currency,
            provider: :stripe,
            current_period_start: Time.current,
            current_period_end: 1.month.from_now,
            next_usage_reset_at: 1.month.from_now
          )
        end
      end
    end
  end
end
