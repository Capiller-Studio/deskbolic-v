# frozen_string_literal: true

module Dashboard
  class EmailTemplatePolicy < ApplicationPolicy
    def index?
      authorized?("email_templates.read", feature: :custom_email_templates_enabled)
    end

    def edit?
      authorized?("email_templates.manage", feature: :custom_email_templates_enabled)
    end

    def update?
      authorized?("email_templates.manage", feature: :custom_email_templates_enabled)
    end

    def create?
      authorized?("email_templates.manage", feature: :custom_email_templates_enabled)
    end

    def destroy?
      authorized?("email_templates.manage", feature: :custom_email_templates_enabled)
    end

    def publish?
      authorized?("email_templates.manage", feature: :custom_email_templates_enabled)
    end

    def discard_draft?
      authorized?("email_templates.manage", feature: :custom_email_templates_enabled)
    end

    def preview?
      authorized?("email_templates.read", feature: :custom_email_templates_enabled)
    end

    def send_test?
      authorized?("email_templates.manage", feature: :custom_email_templates_enabled)
    end

    def variables?
      authorized?("email_templates.read", feature: :custom_email_templates_enabled)
    end
  end
end
