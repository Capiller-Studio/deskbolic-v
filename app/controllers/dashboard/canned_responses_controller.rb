# frozen_string_literal: true

module Dashboard
  class CannedResponsesController < DashboardController
    def create
      @canned_response = CannedResponse.new(canned_response_params)
      @canned_response.account_id = current_account.id

      @canned_response.save
    end
    
    def edit
      @response = CannedResponse.find(params[:id])
    end
  
    def update
      @response = CannedResponse.find(params[:id])
      if @response.update(canned_response_params)
        respond_to do |format|
          format.html { redirect_to macros_settings_path, notice: "Macro updated successfully." }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("response_#{@response.id}", partial: "dashboard/canned_responses/canned_response", locals: { response: @response }) }
        end
      else
        render :edit
      end
    end
    
    def destroy
      @response = CannedResponse.find(params[:id])
      @response.destroy
    
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove("response_#{@response.id}") }
        format.html { redirect_to macros_settings_path, notice: "Macro deleted successfully." }
      end
    end

    private

    def canned_response_params
      params.require(:canned_response).permit(:name, :description)
    end
  end
end