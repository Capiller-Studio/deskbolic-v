# frozen_string_literal: true

module Dashboard
  module Channels
    class ContactFormController < DashboardController
    before_action :set_contact_form_channel, only: %i[edit update destroy]
    before_action :authorize_contact_form_channel

    def index
      @contact_form_channels = current_account.with_shard do
        Channel::ContactForm.where(account: current_account).includes(:inboxes).order(created_at: :desc)
      end
    end

    def new
      @contact_form_channel = Channel::ContactForm.new
      set_associations
    end

    def create
      unless current_account.within_limit?(:channels)
        redirect_to channels_contact_form_index_path, alert: t("dashboard.contact_form_channels.limit_reached", default: "Channel limit reached")
        return
      end

      creator = ::Channels::ChannelCreator.new(
        channel_type: "contact_form",
        channel_params: contact_form_channel_params,
        current_account: current_account
      )

      if creator.call
        @contact_form_channel = creator.channel
        assign_custom_fields
        redirect_to edit_channels_contact_form_path(@contact_form_channel), notice: t("dashboard.contact_form_channels.created", default: "Contact Form Channel created successfully.")
      else
        @contact_form_channel = creator.channel || Channel::ContactForm.new(contact_form_channel_params.except("ordered_fields", "custom_field_ids"))
        set_associations
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      set_associations
    end

    def update
      current_account.with_shard do
        params_to_update = contact_form_channel_params
        
        @contact_form_channel.require_login = params_to_update[:require_login] == "1" || params_to_update[:require_login] == true || params_to_update[:require_login] == "true"
        @contact_form_channel.allow_attachments = params_to_update[:allow_attachments] == "1" || params_to_update[:allow_attachments] == true || params_to_update[:allow_attachments] == "true"
        @contact_form_channel.send_confirmation_email = params_to_update[:send_confirmation_email] == "1" || params_to_update[:send_confirmation_email] == true || params_to_update[:send_confirmation_email] == "true"
        @contact_form_channel.spam_protection_enabled = params_to_update[:spam_protection_enabled] == "1" || params_to_update[:spam_protection_enabled] == true || params_to_update[:spam_protection_enabled] == "true"
        
        params_to_update = params_to_update.except(:require_login, :allow_attachments, :send_confirmation_email, :spam_protection_enabled, :custom_field_ids)

        if @contact_form_channel.update(params_to_update)
          assign_custom_fields
          redirect_to channels_contact_form_index_path, notice: t("dashboard.contact_form_channels.updated", default: "Contact Form Channel updated successfully.")
        else
          set_associations
          render :edit, status: :unprocessable_entity
        end
      end
    end

    def destroy
      current_account.with_shard do
        @contact_form_channel.destroy
      end
      current_account.decrement_usage!(:channels)

      respond_to do |format|
        format.html { redirect_to channels_contact_form_index_path, notice: t("dashboard.contact_form_channels.destroyed", default: "Contact Form Channel deleted.") }
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@contact_form_channel) }
      end
    end

    private

    def assign_custom_fields
      ordered_ids = params.dig(:contact_form_channel, :ordered_fields) || params.dig(:contact_form_channel, :custom_field_ids) || []
      ordered_ids.reject!(&:blank?)
      
      valid_field_ids = current_account.custom_fields.where(id: ordered_ids).pluck(:id).map(&:to_s)
      ordered_ids &= valid_field_ids
      
      settings = params.dig(:contact_form_channel, :field_settings)&.permit!&.to_h || {}
      
      @contact_form_channel.custom_field_resources.destroy_all
      
      ordered_ids.each_with_index do |field_id, index|
        field_setting = settings[field_id] || {}
        
        @contact_form_channel.custom_field_resources.create!(
          custom_field_id: field_id,
          position: index,
          required_override: field_setting[:required_override] == "1",
          configurations: {
            "width" => field_setting[:width] || "full"
          }
        )
      end
    end

    def set_contact_form_channel
      current_account.with_shard do
        @contact_form_channel = Channel::ContactForm.find_by!(id: params[:id], account: current_account)
      end
    end
    
    def set_associations
      current_account.with_shard do
        @email_channels = Channel::Email.where(account: current_account)
        @available_custom_fields = current_account.custom_fields.where(entity_type: [:customer, :conversation])
        @csat_surveys = current_account.csat_surveys
      end
    end

    def authorize_contact_form_channel
      authorize :contact_form_channel
    end

    def contact_form_channel_params
      permitted = params.require(:contact_form_channel).permit(
        :name, :require_login, :allow_attachments, :send_confirmation_email, :spam_protection_enabled,
        :submit_redirect_url, :outbound_channel_id, :outbound_channel_type,
        custom_field_ids: [],
        ordered_fields: [],
        ui_configurations: [:theme_color, :position],
        primary_inbox_attributes: [:id, :csat_survey_enabled, :auto_assign, :csat_survey_id, :conversation_reply_template_id, :business_hour_group_id, sla_policy_ids: []],
        translations_attributes: [:id, :locale, :title, :subtitle, :success_message, :submit_button_text, :_destroy]
      ).to_h

      result = permitted.slice(
        "name", "require_login", "allow_attachments", "send_confirmation_email", "spam_protection_enabled",
        "primary_inbox_attributes", "translations_attributes", "custom_field_ids", "ordered_fields",
        "submit_redirect_url", "outbound_channel_id", "outbound_channel_type"
      )

      if permitted["ui_configurations"].present?
        result["ui_configurations"] = permitted["ui_configurations"].compact_blank
      end

      result
    end
  end
end
end
