# frozen_string_literal: true

module Dashboard
  class EmailTemplateLayoutPolicy < ApplicationPolicy
    def index?
      authorized?("email_templates.read", feature: :email_templates)
    end

    def edit?
      authorized?("email_templates.manage", feature: :email_templates)
    end

    def update?
      authorized?("email_templates.manage", feature: :email_templates)
    end

    def publish?
      authorized?("email_templates.manage", feature: :email_templates)
    end

    def discard_draft?
      authorized?("email_templates.manage", feature: :email_templates)
    end

    def preview?
      authorized?("email_templates.read", feature: :email_templates)
    end
  end
end
