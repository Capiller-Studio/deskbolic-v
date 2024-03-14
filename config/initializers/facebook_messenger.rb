# frozen_string_literal: true

class DeskbolicFacebookProvider < Facebook::Messenger::Configuration::Providers::Base
  # Verify that the given verify token is valid.
  #
  # verify_token - A String describing the application's verify token.
  #
  # Returns a Boolean representing whether the verify token is valid.
  def valid_verify_token?(verify_token)
    # bot.exists?(verify_token: verify_token)
  end

  # Find the right application secret.
  #
  # page_id - An Integer describing a Facebook Page ID.
  #
  # Returns a String describing the application secret.
  def app_secret_for(page_id)
    # bot.find_by(page_id: page_id).app_secret
  end

  # Find the right access token.
  #
  # recipient - A Hash describing the `recipient` attribute of the message coming
  #             from Facebook.
  #
  # Note: The naming of "recipient" can throw you off, but think of it from the
  # perspective of the message: The "recipient" is the page that receives the
  # message.
  #
  # Returns a String describing an access token.
  def access_token_for(recipient)
    Channel::FacebookPage.find_by(page_identifier: recipient["id"]).access_token
  end

  private

  def bot
    Deskbolic::Bot
  end
end

Rails.application.reloader.to_prepare do
  Facebook::Messenger.configure do |config|
    config.provider = DeskbolicFacebookProvider.new
  end

  Facebook::Messenger::Bot.on :message do |_message|
    # TODO: Create a worker to handle new message events

    # For testing purpose

    parsed_message = Parser::FacebookMessageParser.call(response: mesage)
    Channel::FacebookPage.where(page_id: parsed_message.recipient_id).each do |channel|
      Channels::FacebookPages::ConversationCreator.call(
        facebook_page_channel: channel,
        parsed_message:
      )
    end
  end
  Facebook::Messenger::Bot.on :message_echo do |_message|
    # TODO: Create a worker to handle new message events

    # For testing purpose

    parsed_message = Parser::FacebookMessageParser.call(response: mesage)
    Channel::FacebookPage.where(page_id: parsed_message.sender_id).each do |channel|
      Channels::FacebookPages::ConversationCreator.call(
        facebook_page_channel: channel,
        parsed_message:
      )
    end
  end

  Facebook::Messenger::Bot.on :delivery do |delivery|
    # TODO: Create a worker to handle delivery events
  end

  Facebook::Messenger::Bot.on :read do |read|
    # TODO: Create a worker to handle delivery events
  end
end
