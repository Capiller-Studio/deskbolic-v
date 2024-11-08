# frozen_string_literal: true

module Dashboard
  class CannedResponsesController < DashboardController
    def create
      @canned_response = CannedResponse.new(canned_response_params)
      @canned_response.account_id = current_account.id

      @canned_response.save
    end

    private

    def canned_response_params
      params.require(:canned_response).permit(:name, :description)
    end
  end
end