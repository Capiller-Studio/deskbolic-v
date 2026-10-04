# frozen_string_literal: true

module Api
  module Scim
    module V2
      # RFC 7643 Section 6 — ResourceTypes endpoint
      # Returns the list of SCIM resource types this server supports.
      class ResourceTypesController < BaseController
        skip_before_action :authenticate_scim_token!, only: [ :index, :show ]

        RESOURCE_TYPES = [
          {
            schemas: [ "urn:ietf:params:scim:schemas:core:2.0:ResourceType" ],
            id: "User",
            name: "User",
            description: "User Account",
            endpoint: "/api/scim/v2/users",
            schema: "urn:ietf:params:scim:schemas:core:2.0:User",
            meta: {
              resourceType: "ResourceType"
            }
          },
          {
            schemas: [ "urn:ietf:params:scim:schemas:core:2.0:ResourceType" ],
            id: "Group",
            name: "Group",
            description: "Group (Team)",
            endpoint: "/api/scim/v2/groups",
            schema: "urn:ietf:params:scim:schemas:core:2.0:Group",
            meta: {
              resourceType: "ResourceType"
            }
          }
        ].freeze

        def index
          types = RESOURCE_TYPES.map do |rt|
            rt.merge(meta: rt[:meta].merge(location: api_scim_v2_resource_type_url(rt[:id])))
          end

          render(json: {
            schemas: [ "urn:ietf:params:scim:api:messages:2.0:ListResponse" ],
            totalResults: types.size,
            Resources: types
          }, status: :ok)
        end

        def show
          resource_type = RESOURCE_TYPES.find { |rt| rt[:id] == params[:id] }

          unless resource_type
            return render_scim_error(status: :not_found, detail: "ResourceType '#{params[:id]}' not found.")
          end

          render(json: resource_type.merge(
            meta: resource_type[:meta].merge(location: api_scim_v2_resource_type_url(params[:id]))
          ), status: :ok)
        end
      end
    end
  end
end
