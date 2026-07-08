# frozen_string_literal: true

class ConversationReplyMailer < ApplicationMailer
  # Sends an agent's reply back to the customer via email.
  #
  # Template hierarchy (simplified):
  #   1. CSAT template — if message is a CSAT survey and survey has an email_template
  #   2. Inbox custom template — if inbox has a conversation_reply_template (Liquid)
  #   3. System MJML fallback — pre-compiled .html.erb view
  #
  # From address:
  #   - If channel has custom SMTP → "Agent via Inbox" <channel.email>
  #   - Else → "Agent via Inbox" <support@helpbolic.com>
  #
  # Reply-To:
  #   - Uses forward_email domain when available for proper threading
  def reply(conversation, message, fallback_channel = nil)
    @conversation = conversation
    @message = message
    @account = conversation.account
    @inbox = conversation.inbox
    # Priority: Fallback param > Conversation outbound_channel > Inbox channel
    @channel = fallback_channel || conversation.outbound_channel || @inbox.channel

    configure_smtp_settings if @channel.respond_to?(:smtp_enabled?) && @channel.smtp_enabled?

    # Set view variables for the compiled MJML ERB template
    @agent_name = @message.sender.try(:display_name) || "Agent"
    @inbox_name = @inbox.name
    @content = @message.content

    # CSAT survey URL (used by csat_survey.html.erb)
    if @message.csat?
      @csat_survey_url = build_csat_survey_url
    end

    # Try DB template (Liquid), fall back to mailer view
    template = if @message.csat? && @message.csat_survey_response&.csat_survey
      @message.csat_survey_response.csat_survey.email_template
    else
      @inbox.conversation_reply_template
    end

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
      # Falls back to pre-compiled MJML views:
      #   app/views/conversation_reply_mailer/reply.html.erb
      #   app/views/conversation_reply_mailer/csat_survey.html.erb
      view_name = @message.csat? ? "csat_survey" : "reply"

      mail(
        to: customer_email,
        from: reply_from_address,
        reply_to: reply_to_address,
        subject: reply_subject,
        message_id: message_header_id,
        in_reply_to: in_reply_to_header,
        references: references_header
      ) do |format|
        format.html { render "conversation_reply_mailer/#{view_name}" }
      end
    end
  end

  private

  # Liquid template variables using dot notation for user-friendly access:
  #   {{ agent.name }}, {{ agent.email }}
  #   {{ message.content }}
  #   {{ conversation.subject }}, {{ conversation.identifier }}
  #   {{ inbox.name }}
  #   {{ account.name }}
  #   {{ customer.name }}, {{ customer.email }}
  def liquid_variables
    Liquid::ContextBuilderService.call(
      conversation: @conversation,
      agent: @message.sender,
      message: @message,
      template_type: 'conversation_reply'
    )
  end

  def customer_email
    customer = @conversation.customers.first
    @conversation.data.dig("email", "from") || customer&.email
  end

  # From address with display name: "Agent Name via InboxName" <email>
  #   - With custom SMTP: uses channel email
  #   - Without custom SMTP: uses helpbolic system address
  def reply_from_address
    display_name = "#{@agent_name} via #{@inbox_name}"
    sender_email = if @channel.respond_to?(:smtp_enabled?) && @channel.smtp_enabled?
      @channel.email
    else
      helpbolic_from_address
    end

    %("#{display_name}" <#{sender_email}>)
  end

  # Reply-to uses the forward email domain for proper routing back to the platform.
  # Format: reply+<conversation-identifier>@<forward-email-domain>
  def reply_to_address
    domain = if @channel.respond_to?(:forward_email_domain) && @channel.forward_email_domain.present?
      @channel.forward_email_domain
    else
      "#{@conversation.account.identifier.downcase}.helpbolic.com"
    end

    "reply+#{@conversation.identifier}@#{domain}"
  end

  def original_subject
    @conversation.data.dig("email", "subject") || @conversation.title || "Conversation"
  end

  def reply_subject
    sub = original_subject
    sub.start_with?("Re:") ? sub : "Re: #{sub}"
  end

  # Stable Message-ID using helpbolic.com domain (not channel-dependent)
  def message_header_id
    "<#{@message.id}@helpbolic.com>"
  end

  def in_reply_to_header
    @conversation.data.dig("email", "message_id")
  end

  def references_header
    refs = @conversation.data.dig("email", "references") || []
    original_id = @conversation.data.dig("email", "message_id")
    [original_id, *refs].compact.uniq.join(" ")
  end

  def configure_smtp_settings
    options = @channel.smtp_delivery_options
    return if options.blank?

    mail.delivery_method(:smtp, options)
  end

  def build_csat_survey_url
    protocol = Rails.env.development? || Rails.env.test? ? "http" : "https"
    host = ENV.fetch("PORTAL_HOST", "deskbolic.com")
    locale = @conversation.locale || @conversation.customers.first&.locale || I18n.default_locale
    csat_id = @message.csat_response_id || @message.data["csat_response_id"]
    "#{protocol}://csat.#{host}/#{locale}/#{csat_id}"
  end
end
