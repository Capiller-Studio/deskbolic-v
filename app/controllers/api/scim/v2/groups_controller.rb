# frozen_string_literal: true

module Api
  module Scim
    module V2
      # RFC 7644 — Groups endpoint mapped to Teams
      # Maps SCIM Groups to Deskbolic Teams for directory sync.
      # Okta/Azure AD use this to sync group membership → team assignment.
      class GroupsController < BaseController
        SCIM_GROUP_SCHEMA = "urn:ietf:params:scim:schemas:core:2.0:Group"
        SCIM_LIST_SCHEMA  = "urn:ietf:params:scim:api:messages:2.0:ListResponse"

        before_action :set_team, only: %i[show update destroy]

        def index
          current_account.with_shard do
            scope = current_account.teams

            if params[:filter].present?
              scope = apply_filter(scope, params[:filter])
            end

            total_results = scope.count
            start_index = [params[:startIndex].to_i, 1].max
            count = params[:count].present? ? [params[:count].to_i, 1].max : 100

            paginated = scope.order(:name).offset(start_index - 1).limit(count)
            resources = paginated.map { |team| serialize_scim_group(team) }

            render json: {
              schemas: [SCIM_LIST_SCHEMA],
              totalResults: total_results,
              startIndex: start_index,
              itemsPerPage: resources.size,
              Resources: resources
            }, status: :ok
          end
        end

        def show
          current_account.with_shard do
            render json: serialize_scim_group(@team), status: :ok
          end
        end

        def create
          display_name = scim_payload[:displayName] || scim_payload["displayName"]
          if display_name.blank?
            return render_scim_error(
              status: :bad_request,
              detail: "Attribute 'displayName' is required.",
              scim_type: "invalidValue"
            )
          end

          team = current_account.with_shard do
            existing = current_account.teams.find_by("LOWER(name) = ?", display_name.downcase)
            if existing
              return render_scim_error(
                status: :conflict,
                detail: "Group with displayName '#{display_name}' already exists.",
                scim_type: "uniqueness"
              )
            end

            current_account.teams.create!(name: display_name)
          end

          # Sync members if provided
          sync_members!(team) if scim_members.present?

          Auth::AuditLog.log(
            event_type:  :scim_user_created,
            auth_method: :scim,
            status:      :success,
            account:     current_account,
            metadata:    { scim_token_id: current_scim_token.id, group_name: team.name, team_id: team.id }
          )

          response.headers["Location"] = api_scim_v2_group_url(team.id)
          current_account.with_shard do
            render json: serialize_scim_group(team), status: :created
          end
        end

        def update
          if patch_request?
            apply_patch_operations!
          else
            apply_put_update!
          end

          current_account.with_shard do
            @team.reload
            render json: serialize_scim_group(@team), status: :ok
          end
        end

        def destroy
          current_account.with_shard { @team.destroy! }

          Auth::AuditLog.log(
            event_type:  :scim_user_deactivated,
            auth_method: :scim,
            status:      :success,
            account:     current_account,
            metadata:    { scim_token_id: current_scim_token.id, group_name: @team.name, team_id: @team.id }
          )

          head :no_content
        end

        private

        def set_team
          @team = current_account.with_shard do
            current_account.teams.find(params[:id])
          end
        rescue ActiveRecord::RecordNotFound
          render_scim_error(status: :not_found, detail: "Group with ID '#{params[:id]}' was not found in this workspace.")
        end

        def scim_payload
          @scim_payload ||= begin
            if params[:displayName].present? || params[:Operations].present? || params["Operations"].present?
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

        def scim_members
          scim_payload[:members] || scim_payload["members"] || []
        end

        def patch_request?
          scim_payload[:Operations].present? || scim_payload["Operations"].present? || request.patch?
        end

        def apply_patch_operations!
          operations = scim_payload[:Operations] || scim_payload["Operations"] || []

          operations.each do |op|
            op_type = (op[:op] || op["op"]).to_s.downcase
            path    = (op[:path] || op["path"]).to_s.downcase
            value   = op[:value] || op["value"]

            case op_type
            when "replace"
              if path == "displayname" || (path.blank? && value.respond_to?(:key?) && (value.key?("displayName") || value.key?(:displayName)))
                new_name = path == "displayname" ? value : (value["displayName"] || value[:displayName])
                current_account.with_shard { @team.update!(name: new_name) } if new_name.present?
              elsif path == "members" || (path.blank? && value.respond_to?(:key?) && (value.key?("members") || value.key?(:members)))
                members = path == "members" ? value : (value["members"] || value[:members])
                replace_members!(members) if members.is_a?(Array)
              end
            when "add"
              if path == "members"
                add_members!(Array.wrap(value))
              end
            when "remove"
              if path.start_with?("members")
                # Handle members[value eq "user-id"] format
                user_id_match = path.match(/members\[value\s+eq\s+["']?([^"'\]]+)["']?\]/i)
                if user_id_match
                  remove_member!(user_id_match[1])
                elsif value.is_a?(Array)
                  value.each { |m| remove_member!(m["value"] || m[:value]) }
                end
              end
            end
          end
        end

        def apply_put_update!
          display_name = scim_payload[:displayName] || scim_payload["displayName"]
          current_account.with_shard { @team.update!(name: display_name) } if display_name.present?

          # Full member replacement on PUT
          replace_members!(scim_members) if scim_payload.key?(:members) || scim_payload.key?("members")
        end

        def sync_members!(team)
          current_account.with_shard do
            scim_members.each do |member|
              user_id = member[:value] || member["value"]
              next unless user_id
              next unless AccountUser.exists?(account_id: current_account.id, user_id: user_id)

              team.team_users.find_or_create_by!(user_id: user_id)
            end
          end
        end

        def replace_members!(members)
          current_account.with_shard do
            @team.team_users.destroy_all

            Array.wrap(members).each do |member|
              user_id = member[:value] || member["value"]
              next unless user_id
              next unless AccountUser.exists?(account_id: current_account.id, user_id: user_id)

              @team.team_users.create!(user_id: user_id)
            end
          end
        end

        def add_members!(members)
          current_account.with_shard do
            members.each do |member|
              user_id = member[:value] || member["value"]
              next unless user_id
              next unless AccountUser.exists?(account_id: current_account.id, user_id: user_id)

              @team.team_users.find_or_create_by!(user_id: user_id)
            end
          end
        end

        def remove_member!(user_id)
          return unless user_id

          current_account.with_shard do
            @team.team_users.where(user_id: user_id).destroy_all
          end
        end

        def apply_filter(scope, filter_str)
          match = filter_str.match(/\AdisplayName\s+eq\s+["']?([^"']+)["']?\z/i)
          if match
            name = match[1].strip
            scope.where("LOWER(name) = ?", name.downcase)
          else
            scope
          end
        end

        def serialize_scim_group(team)
          members = team.team_users.includes(:user).map do |tu|
            user = tu.user
            {
              value: user.id,
              display: [user.first_name, user.last_name].compact.join(" ").presence || user.email,
              "$ref": api_scim_v2_user_url(user.id)
            }
          end

          {
            schemas: [SCIM_GROUP_SCHEMA],
            id: team.id,
            displayName: team.name,
            members: members,
            meta: {
              resourceType: "Group",
              created: team.created_at&.iso8601,
              lastModified: team.updated_at&.iso8601,
              location: api_scim_v2_group_url(team.id)
            }
          }
        end
      end
    end
  end
end
