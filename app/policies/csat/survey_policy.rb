# frozen_string_literal: true

module Csat
  class SurveyPolicy < ApplicationPolicy
    def index?
      authorized?("csat_surveys.read", feature: :custom_csat)
    end

    def new?
      authorized?("csat_surveys.manage", feature: :custom_csat)
    end

    def create?
      authorized?("csat_surveys.manage", feature: :custom_csat)
    end

    def edit?
      authorized?("csat_surveys.manage", feature: :custom_csat)
    end

    def update?
      authorized?("csat_surveys.manage", feature: :custom_csat)
    end

    def destroy?
      authorized?("csat_surveys.manage", feature: :custom_csat)
    end
  end
end
