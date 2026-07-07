# frozen_string_literal: true

module Dashboard
  module Csat
    class SurveyPolicy < ApplicationPolicy
      def index?
        can?("csat_surveys.read")
      end

      def show?
        can?("csat_surveys.read")
      end

      def create?
        can?("csat_surveys.manage")
      end

      def update?
        can?("csat_surveys.manage")
      end

      def destroy?
        can?("csat_surveys.manage")
      end
    end
  end
end
