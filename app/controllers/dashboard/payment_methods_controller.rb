# frozen_string_literal: true

module Dashboard
  class PaymentMethodsController < DashboardController
    skip_before_action :enforce_active_subscription, only: [ :create, :destroy, :make_default, :setup_intent ]

    def create
      if params[:payment_method_id].blank?
        flash[:alert] = "Payment method token is missing."
        redirect_to(dashboard_billing_path)
        return
      end

      manager = Billing::PaymentMethodManager.new(account: current_account)
      manager.add_stripe_method(params[:payment_method_id])

      # If the account was past_due, adding a card should attempt to pay the outstanding balance
      sub = current_account.subscriptions.order(created_at: :desc).first
      if sub&.past_due?
        SubscriptionRenewalWorker.new.perform
        flash[:notice] = "Payment method added. We are attempting to charge your outstanding balance."
      else
        flash[:notice] = "Payment method added successfully."
      end

      redirect_to(dashboard_billing_path)
    rescue StandardError => e
      flash[:alert] = "Failed to add payment method: #{e.message}"
      redirect_to(dashboard_billing_path)
    end

    def destroy
      pm = current_account.payment_methods.active_methods.find(params[:id])
      manager = Billing::PaymentMethodManager.new(account: current_account)
      manager.remove_method(pm)

      flash[:notice] = "Payment method removed."
      redirect_to(dashboard_billing_path)
    rescue StandardError => e
      flash[:alert] = "Failed to remove payment method: #{e.message}"
      redirect_to(dashboard_billing_path)
    end

    def make_default
      pm = current_account.payment_methods.active_methods.find(params[:id])
      manager = Billing::PaymentMethodManager.new(account: current_account)
      manager.set_default(pm)

      flash[:notice] = "Default payment method updated."
      redirect_to(dashboard_billing_path)
    rescue StandardError => e
      flash[:alert] = "Failed to update default payment method: #{e.message}"
      redirect_to(dashboard_billing_path)
    end

    def setup_intent
      intent = PaymentGateway::Stripe.new(current_account).create_setup_intent
      render(json: { client_secret: intent.client_secret })
    rescue StandardError => e
      render(json: { error: e.message }, status: :unprocessable_entity)
    end
  end
end
