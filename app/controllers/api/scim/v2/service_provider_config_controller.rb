# frozen_string_literal: true

module Api
  module Scim
    module V2
      # RFC 7643 Section 5 — ServiceProviderConfig endpoint
      # Identity providers (Okta, Azure AD) query this during SCIM app setup
      # to discover which SCIM features our implementation supports.
      class ServiceProviderConfigController < BaseController
        skip_before_action :authenticate_scim_token!, only: [:show]

        def show
          render json: {
            schemas: ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"],
            documentationUri: "https://docs.deskbolic.com/scim",
            patch: { supported: true },
            bulk: { supported: false, maxOperations: 0, maxPayloadSize: 0 },
            filter: { supported: true, maxResults: 100 },
            changePassword: { supported: false },
            sort: { supported: false },
            etag: { supported: false },
            authenticationSchemes: [
              {
                type: "oauthbearertoken",
                name: "OAuth Bearer Token",
                description: "Authentication scheme using the OAuth Bearer Token standard (RFC 6750).",
                specUri: "https://tools.ietf.org/html/rfc6750",
                primary: true
              }
            ],
            meta: {
              resourceType: "ServiceProviderConfig",
              location: api_scim_v2_service_provider_config_url
            }
          }, status: :ok
        end
      end
    end
  end
end
