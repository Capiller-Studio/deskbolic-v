# frozen_string_literal: true

module Dashboard
  module AuditLogsHelper
    SENSITIVE_FIELD_PATTERN = /(passw|secret|token|api_key|_key|crypt|salt|certificate|otp|ssn|cvv|cvc|auth|credential|private)/i
    UNFILTERED_FIELDS = %w[event_key key locale_key field_type action_key entity_type routing_type].freeze
    IGNORED_AUDIT_FIELDS = %w[
      id created_at updated_at account_id portal_id views_count inbox_id
      conversation_id contact_id status_id assignable_type assignable_id
      source identifier display_id uuid
    ].freeze

    def audit_log_sensitive_field?(field_name)
      f = field_name.to_s
      return false if UNFILTERED_FIELDS.include?(f)
      return false if f.end_with?("_id") || f.end_with?("_type")

      f.match?(SENSITIVE_FIELD_PATTERN)
    end

    def audit_log_format_value(field, value, max_len: 25)
      return "—" if value.nil?

      if audit_log_sensitive_field?(field) || value.to_s == "[FILTERED]"
        return "••••••••"
      end

      if value.is_a?(Hash)
        safe_hash = sanitize_audit_hash(value)
        return safe_hash.to_json.truncate(max_len)
      end

      if value.is_a?(Array)
        return value.map { |v| audit_log_format_value(field, v, max_len: 12) }.join(", ").truncate(max_len)
      end

      value.to_s.truncate(max_len)
    end

    def audit_log_changes_for(activity)
      return {} unless activity.object_changes.present?

      activity.object_changes.reject do |field, _value|
        IGNORED_AUDIT_FIELDS.include?(field.to_s) || field.to_s.end_with?("_id")
      end
    end

    private

    def sanitize_audit_hash(hash)
      hash.each_with_object({}) do |(k, v), sanitized|
        sanitized[k.to_s] = if audit_log_sensitive_field?(k) || v.to_s == "[FILTERED]"
                              "••••••••"
                            elsif v.is_a?(Hash)
                              sanitize_audit_hash(v)
                            else
                              v
                            end
      end
    end
  end
end
