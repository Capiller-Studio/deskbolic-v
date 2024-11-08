# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Inboxes
  class InboxCreator < ApplicationService
    attr_accessor :inbox_type, :inbox_params, :current_account

    def initialize(inbox_type:, inbox_params:, current_account:)
      self.inbox_type      = inbox_type
      self.inbox_params    = inbox_params
      self.current_account = current_account
    end

    def call
      create_inbox if inbox_type.present?
    end

    private

    def create_inbox
      send("#{inbox_type.underscore.parameterize(separator: "_")}_inbox")
    end

    def email_inbox
      channel = Channel::Email.find(inbox_params[:channel_id])
      channel.inboxes.create!(
        name: inbox_params[:name],
        account: current_account
      )
    end

    def facebook_page_inbox
      channel = Channel::FacebookPage.find(inbox_params[:channel_id])
      channel.inboxes.create!(
        name: inbox_params[:name],
        account: current_account
      )
    end  
  end
end