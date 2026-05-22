# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  module ConversationsHelper
    def assigned_conversation
      @conversation.conversation_members.exists?(member_type: "User")
    end

    def single_emoji_message?(content)
      text = content.to_s.strip
      return false if text.blank?

      clusters = text.scan(/\X/)
      return false unless clusters.one?

      single_emoji_pattern = /
        \A
        (?:
          (?:[\u{1F1E6}-\u{1F1FF}]{2}) |
          (?:[0-9#*]\uFE0F?\u20E3) |
          (?:
            (?:\p{Emoji_Presentation}|\p{Extended_Pictographic}\uFE0F?)
            \p{Emoji_Modifier}?
            (?:
              \u200D
              (?:\p{Emoji_Presentation}|\p{Extended_Pictographic}\uFE0F?)
              \p{Emoji_Modifier}?
            )*
          )
        )
        \z
      /x

      text.match?(single_emoji_pattern)
    end
  end
end