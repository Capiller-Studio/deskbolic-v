# frozen_string_literal: true

module Api
  module Scim
    module V2
      # RFC 7643 Section 7 — Schemas endpoint
      # Returns the SCIM schemas supported by this server.
      # Identity providers use this to discover available attributes.
      class SchemasController < BaseController
        skip_before_action :authenticate_scim_token!, only: [ :index, :show ]

        USER_SCHEMA = {
          id: "urn:ietf:params:scim:schemas:core:2.0:User",
          name: "User",
          description: "User Account",
          attributes: [
            {
              name: "userName",
              type: "string",
              multiValued: false,
              required: true,
              caseExact: false,
              mutability: "readWrite",
              returned: "default",
              uniqueness: "server",
              description: "The user's email address, used as the unique identifier."
            },
            {
              name: "name",
              type: "complex",
              multiValued: false,
              required: false,
              mutability: "readWrite",
              returned: "default",
              subAttributes: [
                { name: "givenName",  type: "string", multiValued: false, required: false, mutability: "readWrite", returned: "default" },
                { name: "familyName", type: "string", multiValued: false, required: false, mutability: "readWrite", returned: "default" },
                { name: "formatted",  type: "string", multiValued: false, required: false, mutability: "readOnly",  returned: "default" }
              ]
            },
            {
              name: "displayName",
              type: "string",
              multiValued: false,
              required: false,
              mutability: "readOnly",
              returned: "default"
            },
            {
              name: "emails",
              type: "complex",
              multiValued: true,
              required: true,
              mutability: "readWrite",
              returned: "default",
              subAttributes: [
                { name: "value",   type: "string",  multiValued: false, required: true,  mutability: "readWrite", returned: "default" },
                { name: "type",    type: "string",  multiValued: false, required: false, mutability: "readWrite", returned: "default" },
                { name: "primary", type: "boolean", multiValued: false, required: false, mutability: "readWrite", returned: "default" }
              ]
            },
            {
              name: "active",
              type: "boolean",
              multiValued: false,
              required: false,
              mutability: "readWrite",
              returned: "default",
              description: "A boolean indicating whether the user is active in this workspace."
            }
          ],
          meta: {
            resourceType: "Schema"
          }
        }.freeze

        GROUP_SCHEMA = {
          id: "urn:ietf:params:scim:schemas:core:2.0:Group",
          name: "Group",
          description: "Group (Team)",
          attributes: [
            {
              name: "displayName",
              type: "string",
              multiValued: false,
              required: true,
              mutability: "readWrite",
              returned: "default",
              uniqueness: "server"
            },
            {
              name: "members",
              type: "complex",
              multiValued: true,
              required: false,
              mutability: "readWrite",
              returned: "default",
              subAttributes: [
                { name: "value",   type: "string", multiValued: false, required: true,  mutability: "immutable", returned: "default" },
                { name: "display", type: "string", multiValued: false, required: false, mutability: "readOnly",  returned: "default" },
                { name: "$ref",    type: "reference", multiValued: false, required: false, mutability: "immutable", returned: "default", referenceTypes: [ "User" ] }
              ]
            }
          ],
          meta: {
            resourceType: "Schema"
          }
        }.freeze

        SCHEMAS = [ USER_SCHEMA, GROUP_SCHEMA ].freeze

        def index
          schemas_with_locations = SCHEMAS.map do |schema|
            schema.merge(meta: schema[:meta].merge(location: api_scim_v2_schema_url(schema[:id])))
          end

          render(json: {
            schemas: [ "urn:ietf:params:scim:api:messages:2.0:ListResponse" ],
            totalResults: schemas_with_locations.size,
            Resources: schemas_with_locations
          }, status: :ok)
        end

        def show
          schema = SCHEMAS.find { |s| s[:id] == params[:id] }

          unless schema
            return render_scim_error(status: :not_found, detail: "Schema '#{params[:id]}' not found.")
          end

          render(json: schema.merge(
            meta: schema[:meta].merge(location: api_scim_v2_schema_url(params[:id]))
          ), status: :ok)
        end
      end
    end
  end
end
