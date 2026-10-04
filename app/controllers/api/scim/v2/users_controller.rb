# frozen_string_literal: true

module Api
  module Scim
    module V2
      class UsersController < BaseController
        SCIM_USER_SCHEMA = "urn:ietf:params:scim:schemas:core:2.0:User"
        SCIM_LIST_SCHEMA = "urn:ietf:params:scim:api:messages:2.0:ListResponse"

        before_action :set_account_user, only: %i[show update destroy]

        def index
          scope = current_account.account_users.includes(:user)

          if params[:filter].present?
            scope = apply_filter(scope, params[:filter])
          end

          total_results = scope.count
          start_index = [ params[:startIndex].to_i, 1 ].max
          count = params[:count].present? ? [ params[:count].to_i, 1 ].max : 100

          account_users = scope.offset(start_index - 1).limit(count)

          resources = account_users.map { |au| serialize_scim_user(au) }

          render(json: {
            schemas: [ SCIM_LIST_SCHEMA ],
            totalResults: total_results,
            startIndex: start_index,
            itemsPerPage: resources.size,
            Resources: resources
          }, status: :ok)
        end

        def show
          render(json: serialize_scim_user(@account_user), status: :ok)
        end

        def create
          email = extract_email
          if email.blank?
            return render_scim_error(
              status: :bad_request,
              detail: "Attribute 'userName' or 'emails' with valid email is required.",
              scim_type: "invalidValue"
            )
          end

          # Check if active member already exists in current workspace
          existing_account_user = current_account.account_users.joins(:user).find_by(users: { email: email })
          if existing_account_user.present? && existing_account_user.active?
            return render_scim_error(
              status: :conflict,
              detail: "User with email '#{email}' is already an active member of this workspace.",
              scim_type: "uniqueness"
            )
          end

          first_name, last_name = extract_name

          account_user = nil
          if existing_account_user.present?
            # Reactivate previously deleted or inactive user
            existing_account_user.update!(status: :active)
            existing_account_user.user.update!(
              first_name: first_name.presence || existing_account_user.user.first_name,
              last_name:  last_name.presence || existing_account_user.user.last_name
            )
            account_user = existing_account_user
          else
            # Provision via Auth::IdentityResolver
            result = Auth::IdentityResolver.call(
              provider:   :saml,
              uid:        email,
              email:      email,
              account:    current_account,
              first_name: first_name,
              last_name:  last_name
            )

            unless result.success?
              return render_scim_error(
                status: :internal_server_error,
                detail: "Failed to provision user: #{result.error}"
              )
            end

            user = result.user
            account_user = current_account.account_users.find_by(user_id: user.id)
          end

          Auth::AuditLog.log(
            event_type:  :scim_user_created,
            auth_method: :scim,
            status:      :success,
            account:     current_account,
            user:        account_user.user,
            email:       account_user.user.email,
            metadata:    { scim_token_id: current_scim_token.id }
          )

          location = api_scim_v2_user_url(account_user.user.id)
          response.headers["Location"] = location
          render(json: serialize_scim_user(account_user), status: :created)
        end

        def update
          if patch_request?
            apply_patch_operations!
          else
            apply_put_update!
          end

          @account_user.reload
          render(json: serialize_scim_user(@account_user), status: :ok)
        end

        def destroy
          @account_user.update!(status: :deleted)

          Auth::AuditLog.log(
            event_type:  :scim_user_deactivated,
            auth_method: :scim,
            status:      :success,
            account:     current_account,
            user:        @account_user.user,
            email:       @account_user.user.email,
            metadata:    { scim_token_id: current_scim_token.id }
          )

          head(:no_content)
        end

        private

        def set_account_user
          user_id = params[:id]
          @account_user = current_account.account_users.includes(:user).find_by(user_id: user_id)

          unless @account_user
            render_scim_error(status: :not_found, detail: "User with ID '#{user_id}' was not found in this workspace.")
          end
        end

        def scim_payload
          @scim_payload ||= begin
            if params[:userName].present? || params[:Operations].present? || params["Operations"].present? || params[:name].present?
              params
            else
              raw = request.raw_post
              if raw.present?
                JSON.parse(raw).with_indifferent_access
              else
                params
              end
            end
          rescue StandardError
            params
          end
        end

        def extract_email
          scim_payload[:userName].presence ||
            scim_payload.dig(:emails, 0, :value) ||
            scim_payload.dig(:emails, 0, "value") ||
            scim_payload.dig("emails", 0, "value")
        end

        def extract_name
          given_name  = scim_payload.dig(:name, :givenName) || scim_payload.dig(:name, "givenName") || scim_payload.dig("name", "givenName")
          family_name = scim_payload.dig(:name, :familyName) || scim_payload.dig(:name, "familyName") || scim_payload.dig("name", "familyName")
          [ given_name, family_name ]
        end

        def patch_request?
          scim_payload[:Operations].present? || scim_payload["Operations"].present? || request.patch?
        end

        def apply_patch_operations!
          operations = scim_payload[:Operations] || scim_payload["Operations"] || []
          user = @account_user.user
          status_changed = false

          operations.each do |op|
            op_type = (op[:op] || op["op"]).to_s.downcase
            path    = (op[:path] || op["path"]).to_s.downcase
            value   = op[:value] || op["value"]

            case op_type
            when "replace", "add"
              if path == "active" || (path.blank? && value.respond_to?(:key?) && (value.key?("active") || value.key?(:active)))
                active_val = (path == "active") ? value : (value["active"].nil? ? value[:active] : value["active"])
                new_status = [ true, "true", 1, "1" ].include?(active_val) ? :active : :deleted
                @account_user.update!(status: new_status)
                log_status_change(new_status)
                status_changed = true
              elsif path == "name.givenname"
                user.update!(first_name: value)
              elsif path == "name.familyname"
                user.update!(last_name: value)
              elsif path == "name.formatted" || (path.blank? && value.respond_to?(:key?) && (value.key?("name") || value.key?(:name)))
                name_hash = path.blank? ? (value["name"] || value[:name]) : {}
                first_name = name_hash["givenName"] || name_hash[:givenName]
                last_name  = name_hash["familyName"] || name_hash[:familyName]
                user.update!(first_name: first_name) if first_name.present?
                user.update!(last_name: last_name) if last_name.present?
              end
            end
          end

          unless status_changed
            Auth::AuditLog.log(
              event_type:  :scim_user_updated,
              auth_method: :scim,
              status:      :success,
              account:     current_account,
              user:        user,
              email:       user.email,
              metadata:    { scim_token_id: current_scim_token.id }
            )
          end
        end

        def apply_put_update!
          user = @account_user.user
          first_name, last_name = extract_name

          user.first_name = first_name if first_name.present?
          user.last_name  = last_name if last_name.present?
          user.save! if user.changed?

          if scim_payload.key?(:active) || scim_payload.key?("active")
            is_active = [ true, "true", 1, "1" ].include?(scim_payload[:active] || scim_payload["active"])
            new_status = is_active ? :active : :deleted
            @account_user.update!(status: new_status)
            log_status_change(new_status)
          end

          Auth::AuditLog.log(
            event_type:  :scim_user_updated,
            auth_method: :scim,
            status:      :success,
            account:     current_account,
            user:        user,
            email:       user.email,
            metadata:    { scim_token_id: current_scim_token.id }
          )
        end

        def log_status_change(new_status)
          event = (new_status == :active) ? :scim_user_updated : :scim_user_deactivated
          Auth::AuditLog.log(
            event_type:  event,
            auth_method: :scim,
            status:      :success,
            account:     current_account,
            user:        @account_user.user,
            email:       @account_user.user.email,
            metadata:    { status: new_status, scim_token_id: current_scim_token.id }
          )
        end

        def apply_filter(scope, filter_str)
          # RFC 7644 filter parsing: userName eq "email@example.com"
          match = filter_str.match(/\AuserName\s+eq\s+["']?([^"']+)["']?\z/i)
          if match
            email = match[1].strip.downcase
            scope.joins(:user).where("LOWER(users.email) = ?", email)
          else
            scope
          end
        end

        def serialize_scim_user(account_user)
          user = account_user.user
          display_name = [ user.first_name, user.last_name ].compact.join(" ").presence || user.email

          {
            schemas: [ SCIM_USER_SCHEMA ],
            id: user.id,
            userName: user.email,
            name: {
              givenName: user.first_name || "",
              familyName: user.last_name || "",
              formatted: display_name
            },
            displayName: display_name,
            emails: [
              {
                value: user.email,
                type: "work",
                primary: true
              }
            ],
            active: account_user.active?,
            meta: {
              resourceType: "User",
              created: account_user.created_at&.iso8601,
              lastModified: account_user.updated_at&.iso8601,
              location: api_scim_v2_user_url(user.id)
            }
          }
        end
      end
    end
  end
end
