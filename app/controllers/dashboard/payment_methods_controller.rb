# frozen_string_literal: true

module Dashboard
  class PaymentMethodsController < DashboardController
    skip_before_action :enforce_active_subscription, only: [:create, :destroy, :make_default]

    def create
      if params[:payment_method_id].blank?
        flash[:alert] = "Payment method token is missing."
        redirect_to dashboard_billing_path
        return
      end

      Billing::PaymentMethodManager.call(account: current_account).add_stripe_method(params[:payment_method_id])

      # If the account was past_due, adding a card should attempt to pay the outstanding balance
      # by renewing the subscription immediately.
      sub = current_account.subscriptions.order(created_at: :desc).first
      if sub&.past_due?
        SubscriptionRenewalWorker.new.perform # We can trigger it asynchronously or inline here
        flash[:notice] = "Payment method added. We are attempting to charge your outstanding balance."
      else
        flash[:notice] = "Payment method added successfully."
      end

      redirect_to dashboard_billing_path
    rescue StandardError => e
      flash[:alert] = "Failed to add payment method: #{e.message}"
      redirect_to dashboard_billing_path
    end

    def destroy
      pm = current_account.payment_methods.active_methods.find(params[:id])
      Billing::PaymentMethodManager.call(account: current_account).remove_method(pm)

      flash[:notice] = "Payment method removed."
      redirect_to dashboard_billing_path
    rescue StandardError => e
      flash[:alert] = "Failed to remove payment method: #{e.message}"
      redirect_to dashboard_billing_path
    end

    def make_default
      pm = current_account.payment_methods.active_methods.find(params[:id])
      Billing::PaymentMethodManager.call(account: current_account).set_default(pm)

      flash[:notice] = "Default payment method updated."
      redirect_to dashboard_billing_path
    rescue StandardError => e
      flash[:alert] = "Failed to update default payment method: #{e.message}"
      redirect_to dashboard_billing_path
    end
  end
end
