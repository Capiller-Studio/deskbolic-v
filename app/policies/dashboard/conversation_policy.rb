# frozen_string_literal: true

module Dashboard
  class ConversationPolicy < ApplicationPolicy
    def index?
      can?("conversations.read")
    end

    def show?
      can?("conversations.read")
    end

    def create?
      authorized?("conversations.write", limit: :conversations_monthly)
    end

    def update?
      can?("conversations.write")
    end

    def destroy?
      can?("conversations.delete")
    end


    # class Scope < Scope
    #   def resolve
    #     scope.where(account_id: account.id)
    #   end
    # end
  end
end
