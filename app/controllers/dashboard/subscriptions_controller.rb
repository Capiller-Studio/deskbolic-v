# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    def new
      @available_plans = Plan.available.where(currency: current_account.currency)
      redirect_to root_path if current_account.subscriptions.any?
    end

    def create
      plan = Plan.available.find(params[:plan_id])
      quantity = params[:quantity].to_i
      
      begin
        Billing::SubscriptionCreator.call(account: current_account, plan: plan, quantity: quantity)
        flash[:notice] = I18n.t("dashboard.billing.subscription_created", default: "Subscription successfully created!")
        redirect_to root_path
      rescue StandardError => e
        flash[:alert] = I18n.t("dashboard.billing.creation_failed", error: e.message, default: "Failed to create subscription: %{error}")
        redirect_to new_subscription_path
      end
    end

    def update
      sub = current_account.subscriptions.find(params[:id])
      
      if params[:plan_id].present?
        new_plan = Plan.available.find(params[:plan_id])
        quantity = params[:quantity].presence&.to_i
        Billing::SubscriptionUpdater.call(subscription: sub, new_plan: new_plan, new_quantity: quantity)
        flash[:notice] = I18n.t("dashboard.billing.plan_updated", plan_name: new_plan.display_name, default: "Plan successfully updated to %{plan_name}.")
      elsif params[:quantity].present?
        Billing::SubscriptionUpdater.call(subscription: sub, new_quantity: params[:quantity].to_i)
        flash[:notice] = I18n.t("dashboard.billing.seats_updated", quantity: params[:quantity], default: "Subscription seats updated to %{quantity}.")
      end

      redirect_to dashboard_billing_path
    rescue ActiveRecord::RecordInvalid => e
      flash[:alert] = I18n.t("dashboard.billing.update_failed", error: e.record.errors.full_messages.join(', '), default: "Failed to update subscription: %{error}")
      redirect_to dashboard_billing_path
    rescue StandardError => e
      flash[:alert] = I18n.t("dashboard.billing.update_failed", error: e.message, default: "Failed to update subscription: %{error}")
      redirect_to dashboard_billing_path
    end

    def cancel
      sub = current_account.subscriptions.find(params[:id])
      
      if sub.cancel!(immediate: false)
        flash[:notice] = I18n.t("dashboard.billing.subscription_cancelled", default: "Subscription has been cancelled and will end at the current billing cycle.")
      else
        flash[:alert] = I18n.t("dashboard.billing.cancel_failed", default: "Failed to cancel subscription.")
      end

      redirect_to dashboard_billing_path
    end

    def resume
      sub = current_account.subscriptions.find(params[:id])
      
      if sub.update(cancelled_at: nil)
        flash[:notice] = I18n.t("dashboard.billing.subscription_resumed", default: "Subscription has been successfully resumed.")
      else
        flash[:alert] = I18n.t("dashboard.billing.resume_failed", default: "Failed to resume subscription.")
      end

      redirect_to dashboard_billing_path
    end
  end
end
