# frozen_string_literal: true

module Dashboard
  class CustomersController < DashboardController
    before_action :set_customer, only: %i[show edit update]

    def index
      authorize(Customer)
      @customers = current_account.customers
        .includes(:address, { avatar_attachment: :blob }, customer_inboxes: { inbox: :channel })
        .order(created_at: :desc)
      @channel_inboxes = current_account.inboxes.includes(:channel).order(:name)
    end

    def show
      authorize(@customer)
    end

    def edit
      authorize(@customer)
    end

    def update
      authorize(@customer)

      if @customer.update(customer_params)
        redirect_to(customer_path(@customer), notice: t("dashboard.customers.flash.updated", default: "Customer updated successfully."))
      else
        render(:edit, status: :unprocessable_entity)
      end
    end

    private

    def set_customer
      @customer = current_account.customers
        .includes(:address, { avatar_attachment: :blob }, { identities: :identity_source }, customer_inboxes: { inbox: :channel })
        .find(params[:id])
    end

    def customer_params
      params.expect(customer: [
        :name,
        :display_name,
        :first_name,
        :middle_name,
        :last_name
      ])
    end
  end
end
