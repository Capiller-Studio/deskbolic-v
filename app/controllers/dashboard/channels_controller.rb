# frozen_string_literal: true

module Dashboard
  class ChannelsController < DashboardController
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
      @selected_type = CHANNEL_TYPES.key?(params[:type]) ? params[:type] : "all"
      @channels_by_type = CHANNEL_TYPES.transform_values do |channel_class_name|
        channel_class_name.constantize.where(account: current_account).order(created_at: :desc).to_a
      end
      @channel_counts = @channels_by_type.transform_values(&:size)
      @channels = @channels_by_type.values.flatten.sort_by(&:created_at).reverse
    end

    def create
      creator = Channels::ChannelCreator.new(
        channel_type: params[:channel_type],
        channel_params: params,
        current_account: current_account,
        current_user: current_user
      )

      if creator.call
        redirect_to(request.referer || channels_path, notice: "Channel Created!")
      else
        error_msg = creator.channel&.errors&.full_messages&.join(", ") || "Failed to create channel"
        redirect_to(request.referer || channels_path, alert: error_msg)
      end
    end
  end
end
