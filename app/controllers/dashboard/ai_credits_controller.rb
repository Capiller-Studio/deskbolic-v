# frozen_string_literal: true

module Dashboard
  class AiCreditsController < DashboardController
    def create
      credits = params[:credits].to_i

      Ai::CreditTopup.call(account: current_account, credits: credits)
      flash[:notice] = I18n.t("dashboard.billing.ai_credits_purchased", count: credits)
      redirect_to(dashboard_billing_path)
    rescue StandardError => e
      flash[:alert] = e.message
      redirect_to(dashboard_billing_path)
    end
  end
end
