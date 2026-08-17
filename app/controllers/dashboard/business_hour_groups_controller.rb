# frozen_string_literal: true

module Dashboard
  class BusinessHourGroupsController < DashboardController
    before_action :set_business_hour_group, only: [:edit, :update, :destroy]

    def index
      authorize(BusinessHourGroup)
      @per_page = params.fetch(:per_page, 10).to_i
      @per_page = 10 unless [10, 20, 50].include?(@per_page)
      @pagy, @business_hour_groups = pagy(
        current_account.business_hour_groups.includes(:business_hours).order(created_at: :desc),
        items: @per_page
      )
    end

    def new
      @business_hour_group = current_account.business_hour_groups.new
      authorize(@business_hour_group)
    end

    def create
      @business_hour_group = current_account.business_hour_groups.new(business_hour_group_params)
      authorize(@business_hour_group)

      if @business_hour_group.save
        flash[:success] = t(".created")
        redirect_to(business_hour_groups_path)
      else
        render(:new, status: :unprocessable_entity)
      end
    end

    def edit
      authorize(@business_hour_group)
    end

    def update
      authorize(@business_hour_group)

      if @business_hour_group.update(business_hour_group_params)
        flash[:success] = t(".updated")
        redirect_to(business_hour_groups_path)
      else
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      authorize(@business_hour_group)
      @business_hour_group.destroy!

      respond_to do |format|
        format.html do
          flash[:success] = t(".destroyed")
          redirect_to(business_hour_groups_path)
        end
        format.turbo_stream do
          flash.now[:success] = t(".destroyed")
        end
      end
    end

    private

    def set_business_hour_group
      @business_hour_group = current_account.business_hour_groups.find(params[:id])
    end

    def business_hour_group_params
      params.require(:business_hour_group).permit(
        :name,
        :description,
        :timezone,
        business_hours_attributes: [
          :id, :day_of_week, :opening_time, :closing_time, :close_from, :close_till, :_destroy
        ]
      )
    end
  end
end
