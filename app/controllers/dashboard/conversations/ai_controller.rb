# frozen_string_literal: true

module Dashboard
  module Conversations
    class AiController < DashboardController
      before_action :set_conversation, only: [ :summarize, :draft_reply ]

      def summarize
        summary = ::Ai::Summarizer.call(
          conversation: @conversation,
          user: current_user
        )

        html_summary = ::Channels::MessageFormatter.parse_ai_markdown_to_html(summary)

        @message = @conversation.messages.create!(
          content: "<strong>AI Summary:</strong><br>#{html_summary}",
          inbox: @conversation.inbox,
          account: @conversation.account,
          sender: current_user,
          source: @conversation.source,
          visibility: :personal
        )

        render(json: { success: true })
      rescue ::AiInsufficientBalanceError => e
        render(json: { success: false, error: e.message }, status: :payment_required)
      rescue => e
        render(json: { success: false, error: "AI Service Error: #{e.message}" }, status: :unprocessable_entity)
      end

      def draft_reply
        draft = ::Ai::Drafter.call(
          conversation: @conversation,
          user: current_user,
          instruction: params[:instruction]
        )

        render(json: { success: true, draft: draft })
      rescue ::AiInsufficientBalanceError => e
        render(json: { success: false, error: e.message }, status: :payment_required)
      rescue => e
        render(json: { success: false, error: "AI Service Error: #{e.message}" }, status: :unprocessable_entity)
      end

      def rewrite_tone
        result = ::Ai::ToneRewriter.call(
          text: params[:text],
          tone: params[:tone],
          account: current_account,
          user: current_user
        )

        render(json: { success: true, rewritten: result })
      rescue ::AiInsufficientBalanceError => e
        render(json: { success: false, error: e.message }, status: :payment_required)
      rescue => e
        render(json: { success: false, error: "AI Service Error: #{e.message}" }, status: :unprocessable_entity)
      end

      def fix_grammar
        result = ::Ai::Client.call(
          account: current_account,
          user: current_user,
          action_type: "fix_grammar",
          model: :lite,
          system_prompt: "Fix all grammar, spelling, and punctuation errors in the following text. Output ONLY the corrected text with no explanation.",
          messages: [ { role: "user", content: params[:text] } ]
        )

        render(json: { success: true, fixed: result })
      rescue ::AiInsufficientBalanceError => e
        render(json: { success: false, error: e.message }, status: :payment_required)
      rescue => e
        render(json: { success: false, error: "AI Service Error: #{e.message}" }, status: :unprocessable_entity)
      end

      def translate
        @conversation = current_account.conversations.find(params[:conversation_id])
        messages_text = @conversation.messages.where(sender_type: "Customer").order(created_at: :desc).limit(5).pluck(:content).reverse.join("\n")

        system_prompt = <<~PROMPT
          You are an expert translator.#{' '}
          Your task is to translate the provided text into the primary language spoken by the Customer in the conversation history.
          If there is no conversation history, or the customer's language cannot be determined, return the original text unchanged.
          Output ONLY the translated text. Do not include any explanations, quotes, or conversational filler.

          --- Customer's Recent Messages for Context ---
          #{messages_text}
        PROMPT

        result = ::Ai::Client.call(
          account: current_account,
          user: current_user,
          action_type: "translate",
          model: :lite,
          system_prompt: system_prompt,
          messages: [ { role: "user", content: params[:text] } ]
        )

        render(json: { success: true, translated: result })
      rescue ::AiInsufficientBalanceError => e
        render(json: { success: false, error: e.message }, status: :payment_required)
      rescue => e
        render(json: { success: false, error: "AI Service Error: #{e.message}" }, status: :unprocessable_entity)
      end

      private

      def set_conversation
        @conversation = current_account.conversations.find(params[:conversation_id])
      end
    end
  end
end
