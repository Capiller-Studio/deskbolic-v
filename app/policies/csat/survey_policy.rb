# frozen_string_literal: true

module Csat
  class SurveyPolicy < ApplicationPolicy
    def index?
      authorized?("csat.read", feature: :custom_csat_enabled)
    end

    def new?
      authorized?("csat.manage", feature: :custom_csat_enabled)
    end

    def create?
      authorized?("csat.manage", feature: :custom_csat_enabled)
    end

    def edit?
      authorized?("csat.manage", feature: :custom_csat_enabled)
    end

    def update?
      authorized?("csat.manage", feature: :custom_csat_enabled)
    end

    def destroy?
      authorized?("csat.manage", feature: :custom_csat_enabled)
    end
  end
end
