# frozen_string_literal: true

module Auth
  class DomainLookupsController < ApplicationController
    protect_from_forgery with: :null_session, if: -> { request.format.json? }

    def show
      query = params[:email].presence || params[:domain].presence
      if query.blank?
        return render(json: { sso_required: false, error: "missing_parameter" }, status: :unprocessable_entity)
      end

      result = Auth::DomainLookupService.call(query)
      render(json: result, status: :ok)
    end
  end
end
