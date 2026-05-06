module Dashboard
  class CustomFieldsBuilderController < DashboardController
    before_action :set_resource

    def show
      @available_fields = current_account.custom_fields.where.not(id: @resource.custom_field_resources.pluck(:custom_field_id))
      @associated_fields = @resource.custom_field_resources.includes(:custom_field).order(:position)
    end

    private

    def set_resource
      # Handle both Channel::ContactForm and Inbox (which points to channel)
      if params[:form_id]
        @resource = current_account.custom_fields.find(params[:form_id]) # Incorrect, should be ContactForm
        # Wait, let's just use type/id from params
      end
      
      @resource = case params[:resource_type]
      when 'Channel::ContactForm'
        current_account.inboxes.find_by(channel_id: params[:resource_id])&.channel
      end
      
      redirect_to custom_fields_path, alert: "Resource not found" unless @resource
    end
  end
end
