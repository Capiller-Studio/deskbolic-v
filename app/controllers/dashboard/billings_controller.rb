# frozen_string_literal: true

module Dashboard
  class BillingsController < DashboardController
    skip_before_action :enforce_active_subscription, only: [ :show, :dismiss_warning ]

    def show
      @wallet = current_account.wallet
      @pagy, @transactions = pagy(current_account.transactions.recent, limit: 10)
      @ai_wallet = current_account.ai_wallet
      @pagy_ai, @ai_transactions = pagy(@ai_wallet.wallet_transactions.recent, page_param: :ai_page, limit: 10) if @ai_wallet
      @ai_grants = @ai_wallet&.credit_grants&.where&.not(grant_type: :refund)&.order(created_at: :desc) || []

      @payment_methods = current_account.payment_methods.active_methods
      @active_subscription = current_account.subscriptions.current.order(created_at: :desc).first
      @available_plans = Plan.available.where(currency: current_account.currency)
      @stripe_publishable_key = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :publishable_key)

      @setup_intent = if @stripe_publishable_key.present?
        PaymentGateway::Stripe.new(current_account).create_setup_intent
      end
    rescue Stripe::StripeError => e
      Rails.logger.error("Stripe setup intent failed: #{e.message}")
      flash.now[:alert] = "Payment setup is temporarily unavailable. Please try again later."
    end

    def dismiss_warning
      session[:billing_warning_dismissed_at] = Time.current.iso8601
      head(:ok)
    end
  end
end
