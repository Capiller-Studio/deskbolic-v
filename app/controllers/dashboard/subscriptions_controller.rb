# frozen_string_literal: true

module Dashboard
  class SubscriptionsController < DashboardController
    skip_before_action :enforce_active_subscription, only: [ :new, :create ]

    def new
      @available_plans = Plan.available.where(currency: current_account.currency)
      redirect_to(root_path) if current_account.subscriptions.current.any?
    end

    def create
      plan = Plan.available.find(params[:plan_id])
      quantity = params[:quantity].to_i
      billing_cycle = params[:billing_cycle].presence || "monthly"

      begin
        Billing::SubscriptionCreator.call(
          account: current_account,
          plan: plan,
          quantity: quantity,
          billing_cycle: billing_cycle.to_sym
        )
        flash[:notice] = I18n.t("dashboard.billing.subscription_created", default: "Subscription successfully created!")
        redirect_to(root_path)
      rescue StandardError => e
        flash[:alert] = I18n.t("dashboard.billing.creation_failed", error: e.message, default: "Failed to create subscription: %{error}")
        redirect_to(new_subscription_path)
      end
    end

    def update
      sub = current_account.subscriptions.find(params[:id])
      new_billing_cycle = resolve_billing_cycle(params)

      if params[:plan_id].present?
        new_plan = Plan.available.find(params[:plan_id])
        quantity = params[:quantity].presence&.to_i
        Billing::SubscriptionUpdater.call(
          subscription: sub,
          new_plan: new_plan,
          new_quantity: quantity,
          new_billing_cycle: new_billing_cycle
        )
        flash[:notice] = I18n.t("dashboard.billing.plan_updated", plan_name: new_plan.display_name, default: "Plan successfully updated to %{plan_name}.")
      elsif params[:quantity].present?
        Billing::SubscriptionUpdater.call(subscription: sub, new_quantity: params[:quantity].to_i)
        flash[:notice] = I18n.t("dashboard.billing.seats_updated", quantity: params[:quantity], default: "Subscription seats updated to %{quantity}.")
      end

      redirect_to(dashboard_billing_path)
    rescue ActiveRecord::RecordInvalid => e
      flash[:alert] = I18n.t("dashboard.billing.update_failed", error: e.record.errors.full_messages.join(", "), default: "Failed to update subscription: %{error}")
      redirect_to(dashboard_billing_path)
    rescue StandardError => e
      flash[:alert] = I18n.t("dashboard.billing.update_failed", error: e.message, default: "Failed to update subscription: %{error}")
      redirect_to(dashboard_billing_path)
    end

    def cancel
      sub = current_account.subscriptions.find(params[:id])

      Billing::SubscriptionCanceller.call(subscription: sub, immediate: false)
      flash[:notice] = I18n.t("dashboard.billing.subscription_cancelled", default: "Subscription has been cancelled and will end at the current billing cycle.")

      redirect_to(dashboard_billing_path)
    rescue StandardError => e
      flash[:alert] = I18n.t("dashboard.billing.cancel_failed_error", error: e.message, default: "Failed to cancel subscription: %{error}")
      redirect_to(dashboard_billing_path)
    end

    def resume
      sub = current_account.subscriptions.find(params[:id])

      if sub.update(cancelled_at: nil)
        flash[:notice] = I18n.t("dashboard.billing.subscription_resumed", default: "Subscription has been successfully resumed.")
      else
        flash[:alert] = I18n.t("dashboard.billing.resume_failed", default: "Failed to resume subscription.")
      end

      redirect_to(dashboard_billing_path)
    end

    private

    def resolve_billing_cycle(params)
      if params[:billing_cycle].present?
        params[:billing_cycle].to_sym
      elsif params[:billing_cycle_annual] == "1"
        :annual
      else
        nil
      end
    end
  end
end
