# frozen_string_literal: true

module Dashboard
  module Channels
    class EmailController < DashboardController
    before_action :set_email_channel, only: %i[show edit update destroy test_smtp test_imap verify_forwarding]
    before_action :authorize_email_channel

    rate_limit to: 5, within: 1.minute, only: %i[test_smtp test_imap verify_forwarding],
      by: -> { current_account.id },
      with: -> { render(json: { success: false, message: "Too many requests. Please wait a minute before trying again." }, status: :too_many_requests) }

    def index
      @email_channels = current_account.with_shard do
        Channel::Email.where(account: current_account).includes(:inboxes).order(created_at: :desc)
      end
    end

    def show; end

    def new
      @email_channel = Channel::Email.new
    end

    def edit; end
    def create
      unless current_account.within_limit?(:channels)
        redirect_to(channels_email_index_path, alert: t("dashboard.email_channels.limit_reached"))
        return
      end

      creator = ::Channels::ChannelCreator.new(
        channel_type: "email",
        channel_params: email_channel_params,
        current_account: current_account,
        current_user: current_user
      )

      if creator.call
        @email_channel = creator.channel
        redirect_to(edit_channels_email_path(@email_channel), notice: t("dashboard.email_channels.created"))
      else
        @email_channel = creator.channel || Channel::Email.new(email_channel_params)
        render(:new, status: :unprocessable_entity)
      end
    end


    def update
      current_account.with_shard do
        if @email_channel.update(email_channel_params)
          redirect_to(channels_email_index_path, notice: t("dashboard.email_channels.updated"))
        else
          render(:edit, status: :unprocessable_entity)
        end
      end
    end

    def destroy
      current_account.with_shard do
        @email_channel.destroy
      end
      current_account.decrement_usage!(:channels)

      respond_to do |format|
        format.html { redirect_to(channels_email_index_path, notice: t("dashboard.email_channels.destroyed"), status: :see_other) }
        format.turbo_stream { redirect_to(channels_email_index_path, notice: t("dashboard.email_channels.destroyed"), status: :see_other) }
      end
    end

    # POST /email_channels/:id/test_smtp
    def test_smtp
      config = smtp_params_from_form

      return render(json: { success: false, message: "SMTP server address is required." }) if config[:address].blank?

      begin
        require "net/smtp"
        smtp = Net::SMTP.new(config[:address], config[:port] || 587)
        smtp.enable_starttls_auto if config[:enable_starttls] != "false"
        smtp.open_timeout = 10
        smtp.read_timeout = 10

        smtp.start(config[:domain] || "localhost", config[:username], config[:password], (config[:authentication] || "plain").to_sym) do |s|
          # Connection successful — EHLO handshake passed
        end

        render(json: { success: true, message: "SMTP connection successful!" })
      rescue => e
        render(json: { success: false, message: "SMTP error: #{e.message}" })
      end
    end

    # POST /email_channels/:id/test_imap
    def test_imap
      config = imap_params_from_form

      return render(json: { success: false, message: "IMAP server address is required." }) if config[:address].blank?

      begin
        require "net/imap"
        imap = Net::IMAP.new(
          config[:address],
          port: config[:port] || 993,
          ssl: config[:enable_ssl] != "false"
        )
        imap.login(config[:username], config[:password])
        imap.select("INBOX")
        mail_count = imap.status("INBOX", [ "MESSAGES" ])["MESSAGES"]
        imap.logout
        imap.disconnect

        render(json: { success: true, message: "IMAP connected! #{mail_count} messages in INBOX." })
      rescue => e
        render(json: { success: false, message: "IMAP error: #{e.message}" })
      end
    end

    # POST /email_channels/:id/verify_forwarding
    def verify_forwarding
      if ::Channels::Email::ForwardEmailVerifier.call(@email_channel)
        render(json: { success: true, message: "Verification email sent to #{@email_channel.email}. We are waiting to receive it." })
      else
        render(json: { success: false, message: "Failed to send verification email. Please check your setup." })
      end
    end

    private

    def set_email_channel
      current_account.with_shard do
        @email_channel = Channel::Email.find_by!(id: params[:id], account: current_account)
      end
    end

    def authorize_email_channel
      authorize(:email_channel)
    end

    def email_channel_params
      permitted = params.expect(
        email_channel: [ :name, :email, :imap_enabled, :smtp_enabled,
        smtp_configurations: [ :address, :port, :username, :password, :domain, :authentication, :enable_starttls ],
        imap_configurations: [ :address, :port, :username, :password, :enable_ssl ],
        primary_inbox_attributes: [ :id, :reopen_window_seconds, :csat_survey_enabled, :auto_assign, :csat_survey_id, :conversation_reply_template_id, :business_hour_group_id, sla_policy_ids: [], user_ids: [], team_ids: [] ] ]
      )

      # Convert nested params from ActionController::Parameters to plain Hash
      result = permitted.slice(:name, :email, :imap_enabled, :smtp_enabled, :primary_inbox_attributes).to_h

      if permitted[:smtp_configurations].present?
        smtp = permitted[:smtp_configurations].to_h
        result[:smtp_configurations] = smtp.compact_blank
      end

      if permitted[:imap_configurations].present?
        imap = permitted[:imap_configurations].to_h
        result[:imap_configurations] = imap.compact_blank
      end

      result
    end

    def smtp_params_from_form
      raw = params.dig(:email_channel, :smtp_configurations) || {}
      {
        address: raw[:address],
        port: raw[:port].presence&.to_i,
        username: raw[:username],
        password: raw[:password],
        domain: raw[:domain],
        authentication: raw[:authentication],
        enable_starttls: raw[:enable_starttls]
      }
    end

    def imap_params_from_form
      raw = params.dig(:email_channel, :imap_configurations) || {}
      {
        address: raw[:address],
        port: raw[:port].presence&.to_i,
        username: raw[:username],
        password: raw[:password],
        enable_ssl: raw[:enable_ssl]
      }
    end
    end
  end
end
