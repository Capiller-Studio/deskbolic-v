# frozen_string_literal: true

class ConversationReplyMailer < ApplicationMailer
  # Sends an agent's reply back to the customer via email
  # Uses Liquid DB template if account has one, otherwise falls back to mailer view
  def reply(conversation, message)
    @conversation = conversation
    @message = message
    @account = conversation.account
    @inbox = conversation.inbox
    # Priority: Conversation outbound_channel > Inbox channel
    @channel = conversation.outbound_channel || @inbox.channel

    configure_smtp_settings if @channel.respond_to?(:smtp_enabled?) && @channel.smtp_enabled?

    # Try DB template (Liquid), fall back to mailer view
    template = EmailTemplate.for_account(@account, EmailTemplate::CONVERSATION_REPLY)

    if template
      rendered_subject = template.render_subject(liquid_variables)
      rendered_body = template.render_body(liquid_variables)

      mail(
        to: customer_email,
        from: reply_from_address,
        reply_to: reply_to_address,
        subject: rendered_subject,
        message_id: message_header_id,
        in_reply_to: in_reply_to_header,
        references: references_header
      ) do |format|
        format.html { render html: rendered_body.html_safe }
      end
    else
      # Falls back to app/views/conversation_reply_mailer/reply.html.slim
      mail(
        to: customer_email,
        from: reply_from_address,
        reply_to: reply_to_address,
        subject: reply_subject,
        message_id: message_header_id,
        in_reply_to: in_reply_to_header,
        references: references_header
      )
    end
  end

  private

  def liquid_variables
    {
      "agent_name" => @message.sender.try(:display_name) || "Agent",
      "message_content" => @message.content,
      "subject" => original_subject,
      "identifier" => @conversation.identifier,
      "inbox_name" => @inbox.name
    }
  end

  def customer_email
    customer = @conversation.customers.first
    @conversation.data.dig("email", "from") || customer&.email
  end

  def reply_from_address
    @channel.respond_to?(:email) ? @channel.email : default_from_address
  end

  def reply_to_address
    domain = reply_from_address.split("@").last
    "reply+#{@conversation.identifier}@#{domain}"
  end

  def original_subject
    @conversation.data.dig("email", "subject") || @conversation.title || "Conversation"
  end

  def reply_subject
    sub = original_subject
    sub.start_with?("Re:") ? sub : "Re: #{sub}"
  end

  def message_header_id
    "<#{@message.id}@#{mail_domain}>"
  end

  def in_reply_to_header
    @conversation.data.dig("email", "message_id")
  end

  def references_header
    refs = @conversation.data.dig("email", "references") || []
    original_id = @conversation.data.dig("email", "message_id")
    [original_id, *refs].compact.uniq.join(" ")
  end

  def mail_domain
    reply_from_address.split("@").last
  end

  def configure_smtp_settings
    options = @channel.smtp_delivery_options
    return if options.blank?

    mail.delivery_method(:smtp, options)
  end
end
