# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  module PlansHelper
    def plan_features(plan)
      limits = [
        limit_feature("Customers", plan.limit_for("customers")),
        limit_feature("Conversations/month", plan.limit_for("conversations_monthly")),
        limit_feature("Messages/month", plan.limit_for("messages_monthly")),
        retention_feature(plan.limit_for("data_retention_months"))
      ]
      feature_labels = {
        "sla" => "SLA management", "api_access" => "API access", "csat" => "CSAT",
        "email_templates" => "Email templates", "custom_csat" => "Custom CSAT",
        "automations" => "Automations", "audit_logs" => "Audit logs",
        "teams" => "Teams", "roles" => "Roles",
        "custom_roles" => "Custom roles", "custom_branding" => "Custom branding",
        "assignment_policies" => "Assignment policies", "identity_sources" => "Identity sources"
      }

      limits + feature_labels.filter_map { |key, label| label if plan.feature_enabled?(key) }
    end

    def limit_feature(label, limit)
      value = limit.to_i.negative? ? "Unlimited" : number_with_delimiter(limit)
      "#{value} #{label.downcase}"
    end

    def retention_feature(months)
      "#{months} months data retention"
    end

    def boolean_feature(label, enabled)
      enabled ? label : nil
    end
  end
end
