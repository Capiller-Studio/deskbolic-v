# frozen_string_literal: true

module Dashboard
  class AuditLogPolicy < ApplicationPolicy
    def index?
      authorized?("audit_logs.read", feature: :audit_logs)
    end

    def revert?
      authorized?("audit_logs.manage", feature: :audit_logs)
    end
  end
end
