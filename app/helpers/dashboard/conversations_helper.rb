# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  module ConversationsHelper
    def assigned_conversation
      @conversation.conversation_members.any? { |member| member.member_type == "User" }
    end
  end
end