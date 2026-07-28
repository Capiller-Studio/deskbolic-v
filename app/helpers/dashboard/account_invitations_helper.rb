# frozen_string_literal: true

module Dashboard
  module AccountInvitationsHelper
    INVITATION_PERMISSION_PREVIEW_LIMIT = 4
    INVITATION_ROLE_BADGE_LIMIT = 3

    def invitation_permission_labels(role)
      role.permissions.to_h.flat_map do |resource, actions|
        actions.to_h.filter_map do |action, policy|
          next unless invitation_permission_granted?(policy)

          action_label = t(
            "dashboard.account_invitations.permissions.actions.#{action}",
            default: action.to_s.humanize
          )
          resource_label = t(
            "dashboard.account_invitations.permissions.resources.#{resource}",
            default: resource.to_s.humanize
          )

          t(
            "dashboard.account_invitations.permissions.label",
            action: action_label,
            resource: resource_label,
            default: "%{action} %{resource}"
          )
        end
      end
    end

    def invitation_permission_labels_for(roles)
      roles.flat_map { |role| invitation_permission_labels(role) }.uniq
    end

    def invitation_role_description(role)
      permission_count = invitation_permission_labels(role).size
      resource_count = role.permissions.to_h.count do |_resource, actions|
        actions.to_h.any? { |_action, policy| invitation_permission_granted?(policy) }
      end

      areas = t(
        "dashboard.account_invitations.permissions.areas",
        count: resource_count,
        default: resource_count == 1 ? "1 area" : "#{resource_count} areas"
      )

      t(
        "dashboard.account_invitations.permissions.summary",
        count: permission_count,
        areas: areas,
        default: permission_count == 1 ? "1 permission across %{areas}" : "%{count} permissions across %{areas}"
      )
    end

    def invitation_visible_permissions(permission_labels, limit: INVITATION_PERMISSION_PREVIEW_LIMIT)
      permission_labels.first(limit)
    end

    def invitation_remaining_permissions_count(permission_labels, limit: INVITATION_PERMISSION_PREVIEW_LIMIT)
      [permission_labels.size - limit, 0].max
    end

    def invitation_more_permissions_text(count)
      t(
        "dashboard.account_invitations.permissions.more",
        count: count,
        default: "And %{count} more"
      )
    end

    def invitation_no_permissions_text
      t(
        "dashboard.account_invitations.permissions.none",
        default: "No permissions assigned"
      )
    end

    private

    def invitation_permission_granted?(policy)
      policy == true || policy == "true" || policy.is_a?(Hash)
    end
  end
end
