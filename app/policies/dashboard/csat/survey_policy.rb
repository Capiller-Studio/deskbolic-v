# frozen_string_literal: true

module Dashboard
  module Csat
    class SurveyPolicy < ApplicationPolicy
      def index?
        authorized?("csat_surveys.read", feature: :csat)
      end

      def show?
        authorized?("csat_surveys.read", feature: :csat)
      end

      def create?
        authorized?("csat_surveys.manage", feature: :csat, limit: :csat_surveys)
      end

      def update?
        authorized?("csat_surveys.manage", feature: :csat)
      end

      def destroy?
        authorized?("csat_surveys.manage", feature: :csat)
      end
    end
  end
end
