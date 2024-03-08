# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # routing(
  #   -> (inbound_email) { replay_email?(inbound_email) } => :reply
  # )

  routing(
    ->(inbound_email) { new_conversation?(inbound_email) } => :conversation
  )

  # TODO: WIP and refactor to a service

  def self.replay_email?(inbound_email)
    inbound_email.mail.to.to_a.any? { |email| email.include?("pattern") }
  end

  def self.new_conversation?(_inbound_email)
    true
  end

  def self.find_email_channel(inbound_email); end
end
