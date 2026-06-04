# frozen_string_literal: true

module Dashboard
  class WalletsController < DashboardController
    def topup
      amount = params[:amount].to_f

      currency = current_account.currency.downcase
      
      limits = if currency == "krw"
                 { min: 10000.0, max: 50000000.0 }
               else
                 { min: 10.0, max: 50000.0 }
               end

      if amount < limits[:min] || amount > limits[:max]
        min_formatted = ActionController::Base.helpers.number_to_currency(limits[:min], unit: currency.upcase + " ")
        max_formatted = ActionController::Base.helpers.number_to_currency(limits[:max], unit: currency.upcase + " ")
        flash[:alert] = I18n.t("dashboard.billing.topup_limit_error", min: min_formatted, max: max_formatted, default: "Top-up amount must be between %{min} and %{max}.")
        redirect_to dashboard_billing_path
        return
      end

      Billing::WalletTopup.call(account: current_account, amount: amount)
      
      flash[:notice] = "Wallet topped up with #{ActionController::Base.helpers.number_to_currency(amount)}"
      redirect_to dashboard_billing_path
    rescue StandardError => e
      flash[:alert] = "Top-up failed: #{e.message}"
      redirect_to dashboard_billing_path
    end
  end
end
