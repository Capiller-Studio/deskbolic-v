# frozen_string_literal: true

module Dashboard
  class ConversationPolicy < ApplicationPolicy
    def index?
      # return !record.where.not(account: account).exists? if record.is_a?(ActiveRecord::Relation)

      true
    end


    # class Scope < Scope
    #   def resolve
    #     scope.where(account_id: account.id)
    #   end
    # end
  end
end