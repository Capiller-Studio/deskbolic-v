module Dashboard
  class FieldResourcesController < DashboardController
    before_action :set_resource

    def create
      @custom_field = current_account.custom_fields.find(params[:custom_field_id])
      @field_resource = @resource.field_resources.find_or_initialize_by(custom_field: @custom_field)

      if @field_resource.save
        render(json: { success: true })
      else
        render(json: { success: false, errors: @field_resource.errors.full_messages }, status: :unprocessable_entity)
      end
    end

    def destroy
      @field_resource = @resource.field_resources.find_by!(custom_field_id: params[:id])
      @field_resource.destroy
      render(json: { success: true })
    end

    def sort
      params[:resource_ids].each_with_index do |id, index|
        @resource.field_resources.where(custom_field_id: id).update_all(position: index + 1)
      end
      render(json: { success: true })
    end

    private

    def set_resource
      resource_type = params[:resource_type]
      @resource = if resource_type == "Channel::ContactForm"
        current_account.portals.find(params[:resource_id]) rescue current_account.inboxes.find_by(channel_id: params[:resource_id])&.channel
      end

      # Simplified lookup for now
      @resource ||= current_account.inboxes.find_by(channel_id: params[:resource_id])&.channel if params[:resource_id]

      render(json: { error: "Resource not found" }, status: :not_found) unless @resource
    end
  end
end
