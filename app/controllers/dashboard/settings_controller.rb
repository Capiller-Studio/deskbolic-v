# frozen_string_literal: true

module Dashboard
  class SettingsController < DashboardController
    CHANNEL_TYPES = {
      "email" => "Channel::Email",
      "web_widget" => "Channel::WebWidget",
      "contact_form" => "Channel::ContactForm",
      "facebook" => "Channel::FacebookPage",
      "instagram" => "Channel::Instagram",
      "whatsapp" => "Channel::Whatsapp",
      "custom" => "Channel::Custom"
    }.freeze

    def index
    end

    def channels
      @selected_type = CHANNEL_TYPES.key?(params[:type]) ? params[:type] : "all"
      @channels_by_type = CHANNEL_TYPES.transform_values do |channel_class_name|
        channel_class_name.constantize.where(account: current_account).order(created_at: :desc).to_a
      end
      @channel_counts = @channels_by_type.transform_values(&:size)
      @channels = @channels_by_type.values.flatten.sort_by(&:created_at).reverse
    end

    def canned_responses
      @canned_responses = current_account.canned_responses.order(created_at: :desc)
      return if params[:search].blank?

      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%"
      @canned_responses = @canned_responses.where(
        "name ILIKE :query OR description ILIKE :query",
        query: query
      )
    end



    def office_timings; end

    def team_inboxes
      @teams = current_account.teams.all
    end

    def inboxes
      @inboxes = current_account.inboxes.includes(:channel, :inbox_users, :inbox_teams, :teams).order(:name)
      @account_users = current_account.account_users.includes(:roles, user: { avatar_attachment: :blob })
      @teams = current_account.teams.order(:name)
    end


    def messenger; end

    def tickets; end
  end
end
