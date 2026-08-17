# frozen_string_literal: true

module Dashboard
  module Conversations
    class CannedResponsesController < DashboardController
      before_action :set_conversation

      def index
        @canned_responses = current_account.canned_responses.active

        if params[:q].present?
          @canned_responses = @canned_responses.where("name ILIKE ?", "%#{params[:q]}%")
        end

        @canned_responses = @canned_responses.order(created_at: :desc)
        @pagy, @canned_responses = pagy(@canned_responses, page: params[:page] || 1, items: 15)

        # Parse Liquid variables on the fly
        parsed_responses = @canned_responses.map do |response|
          liquid_vars = Liquid::ContextBuilderService.call(
            conversation: @conversation,
            agent: current_user,
            template_type: "canned_response"
          )

          liquid_template = Liquid::Template.parse(response.description)
          rendered_content = liquid_template.render(liquid_vars)

          {
            id: response.id,
            name: response.name,
            description: rendered_content
          }
        end

        render(json: {
          canned_responses: parsed_responses,
          meta: {
            current_page: @pagy.page,
            next_page: @pagy.next,
            total_pages: @pagy.pages
          }
        })
      end

      private

      def set_conversation
        @conversation = current_account.conversations.find(params[:conversation_id])
      end
    end
  end
end
