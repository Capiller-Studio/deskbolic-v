# frozen_string_literal: true

module Dashboard
  class CannedResponsesController < DashboardController
    def index
      @canned_responses = current_account.canned_responses.order(created_at: :desc)
      if params[:search].present?
        query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%"
        @canned_responses = @canned_responses.where(
          "name ILIKE :query OR description ILIKE :query",
          query: query
        )
      end
    end

    def edit
      @response = current_account.canned_responses.find(params[:id])
    end

    def create
      @canned_response = CannedResponse.new(canned_response_params)
      @canned_response.account_id = current_account.id

      redirect_to(request.referer || canned_responses_path) if @canned_response.save
    end

    def update
      @response = current_account.canned_responses.find(params[:id])
      if @response.update(canned_response_params)
        respond_to do |format|
          format.html { redirect_to(canned_responses_path, notice: "Macro updated successfully.") }
          format.turbo_stream do
            render(turbo_stream: turbo_stream.replace("response_#{@response.id}",
              partial: "dashboard/canned_responses/canned_response", locals: { response: @response }))
          end
        end
      else
        render(:edit)
      end
    end

    def destroy
      @response = current_account.canned_responses.find(params[:id])
      @response.destroy

      respond_to do |format|
        format.turbo_stream { render(turbo_stream: turbo_stream.remove("response_#{@response.id}")) }
        format.html { redirect_to(canned_responses_path, notice: "Macro deleted successfully.") }
      end
    end

    private

    def canned_response_params
      params.expect(canned_response: [ :name, :description ])
    end
  end
end
