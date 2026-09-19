# frozen_string_literal: true

module Api
  module Scim
    module V2
      class BaseController < ActionController::API
        SCIM_CONTENT_TYPE = "application/scim+json; charset=utf-8"
        SCIM_ERROR_SCHEMA = "urn:ietf:params:scim:api:messages:2.0:Error"

        before_action :authenticate_scim_token!
        before_action :set_scim_content_type

        attr_reader :current_account, :current_scim_token

        rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

        private

        def set_scim_content_type
          response.headers["Content-Type"] = SCIM_CONTENT_TYPE
        end

        def authenticate_scim_token!
          auth_header = request.headers["Authorization"].to_s
          unless auth_header.start_with?("Bearer ")
            return render_scim_error(
              status: :unauthorized,
              detail: "Missing or malformed Authorization header. Expected 'Bearer <token>'."
            )
          end

          raw_token = auth_header.sub(/\ABearer\s+/, "").strip
          @current_scim_token = Auth::ScimToken.authenticate(raw_token)

          if @current_scim_token.nil? || @current_scim_token.expired?
            return render_scim_error(
              status: :unauthorized,
              detail: "Invalid or expired SCIM bearer token."
            )
          end

          @current_account = @current_scim_token.account
          Current.account = @current_account

          unless @current_account.feature_enabled?(:scim) || @current_account.feature_enabled?(:sso)
            return render_scim_error(
              status: :forbidden,
              detail: "SCIM directory synchronization is not enabled on your workspace plan."
            )
          end

          @current_scim_token.touch_last_used!
        end

        def handle_not_found
          render_scim_error(status: :not_found, detail: "Resource not found.")
        end

        def render_scim_error(status:, detail:, scim_type: nil)
          status_code = Rack::Utils.status_code(status)
          payload = {
            schemas: [SCIM_ERROR_SCHEMA],
            status: status_code.to_s,
            detail: detail
          }
          payload[:scimType] = scim_type if scim_type.present?

          render json: payload, status: status, content_type: SCIM_CONTENT_TYPE
        end
      end
    end
  end
end
