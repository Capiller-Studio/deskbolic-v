# frozen_string_literal: true

module Dashboard
  module Settings
    class CsatController < DashboardController
      def show
        # Render the CSAT settings page
      end

      def update
        # CSAT is a feature flag. If they enable it, we set the bit.
        if params[:csat_enabled] == "true"
          current_account.csat_enabled = true
        else
          current_account.csat_enabled = false
        end

        if current_account.save
          redirect_to(settings_csat_path, notice: t(".updated", default: "CSAT settings updated successfully"))
        else
          render(:show, status: :unprocessable_entity)
        end
      end
    end
  end
end
