# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Conversations
  class ConversationCreator < ApplicationService
    attr_accessor :conversation_source, :inbox, :message, :channel, :sender, :customer, 
                  :event, :account, :conversation

    def initialize(channel:, message:, event: :message, sender: nil, customer: nil, conversation_source:, account: nil)
      self.conversation_source  = conversation_source
      self.channel              = channel
      self.message              = message
      self.sender               = sender
      self.customer             = customer
      self.event                = event
      self.account              = account || channel.account
      self.inbox                = channel.inboxes.first
    end
    
    def call
      find_or_create_conversation
      create_message
    end
    
    def find_or_create_conversation
      find_conversation || create_conversation
      find_or_create_conversation_member
    end

    def find_conversation
      self.conversation = customer.conversations.where(inbox: inbox).find_by(account: account)
    end
    
    def create_conversation
      self.conversation = account.conversations.create!(
        inbox: inbox,
        source: conversation_source,
        identifier: SecureRandom.uuid,
        data: {}
      )
    end
    
    def find_or_create_conversation_member
      [customer, sender].each do |member|
        conversation.conversation_members.find_or_create_by!(conversation: conversation, member: member, account: account)
      end
    end
    
    def create_message 
      self.message = conversation.messages.create!(content: message, inbox: inbox, account: account, sender: sender)
        
      Channels::ServicePicker.call(conversation: conversation, message: message)
    end
  end
end
