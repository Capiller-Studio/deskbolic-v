# frozen_string_literal: true

module Dashboard
  class BillingsController < DashboardController
    skip_before_action :enforce_active_subscription, only: [:show, :dismiss_warning]

    def show
      @wallet = current_account.wallet
      @pagy, @transactions = pagy(current_account.transactions.recent, limit: 10)
      @payment_methods = current_account.payment_methods.active_methods
      @active_subscription = current_account.subscriptions.order(created_at: :desc).first
      @available_plans = Plan.available.where(currency: current_account.currency)
      @setup_intent = begin
        PaymentGateway::Stripe.new(current_account).create_setup_intent
      rescue StandardError => e
        Rails.logger.warn "Stripe setup failed (likely missing API keys): #{e.message}"
        OpenStruct.new(client_secret: "mock_secret_for_ui_testing")
      end
    end

    def dismiss_warning
      session[:billing_warning_dismissed_at] = Time.current.iso8601
      head :ok
    end
  end
end
