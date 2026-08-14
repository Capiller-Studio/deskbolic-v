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
      @channels = @selected_type == "all" ? @channels_by_type.values.flatten.sort_by(&:created_at).reverse : @channels_by_type.fetch(@selected_type)
    end

    def canned_responses
      @canned_responses      = CannedResponse.where(account: current_account).all
      @canned_responses      = @canned_responses.where("name ILIKE ?",
"%#{params[:search]}%") if params[:search].present?
    end


    
    def office_timings; end
    
    def team_inboxes
      @teams = current_account.teams.all
    end
    

    def messenger; end
    
    def tickets; end
  end
end
