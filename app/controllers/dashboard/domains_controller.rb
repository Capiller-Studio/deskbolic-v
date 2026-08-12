# frozen_string_literal: true

module Dashboard
  class DomainsController < DashboardController
    before_action :set_domain, only: [:edit, :update, :destroy, :verify_dns]

    def index
      @domains = current_account.domains.order(created_at: :desc)
      @subdomain = @domains.find_by(domain_type: :subdomain)
      @custom_domains = @domains.custom_domains
    end

    def new
      @domain = Domain.new(domain_type: :custom)
    end

    def create
      if domain_params[:domain_type] == "subdomain"
        @domain = Domains::CreateSubdomain.call(
          account: current_account,
          slug: domain_params[:value],
          name: domain_params[:name]
        )
      else
        unless current_account.feature_enabled?(:custom_domains)
          @domain = Domain.new(domain_params)
          @domain.errors.add(:domain_type, I18n.t("dashboard.domains.custom_domain_not_supported", default: "Custom domains are not supported on your current plan."))
          raise ActiveRecord::RecordInvalid, @domain
        end

        @domain = Domain.new(domain_params)
        @domain.errors.add(:name, :blank) if domain_params[:name].blank?
        @domain.errors.add(:value, :blank) if domain_params[:value].blank?
        raise ActiveRecord::RecordInvalid, @domain if @domain.errors.any?

        @domain = Domains::CreateCustomDomain.call(
          account: current_account,
          value: domain_params[:value],
          name: domain_params[:name]
        )
      end

      redirect_to domains_path, notice: t("dashboard.domains.create.success")
    rescue ActiveRecord::RecordInvalid => e
      @domain = e.record
      render :new, status: :unprocessable_entity
    end

    def edit; end

    def update
      @domain.assign_attributes(update_params)

      if update_params[:name].blank?
        @domain.errors.add(:name, :blank)
        render :edit, status: :unprocessable_entity
      elsif @domain.save
        redirect_to domains_path, notice: t("dashboard.domains.update.success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @domain.portal.present?
        redirect_to domains_path, alert: t("dashboard.domains.destroy.portal_attached")
      else
        @domain.destroy!
        redirect_to domains_path, notice: t("dashboard.domains.destroy.success")
      end
    end

    def verify_dns
      result = Domains::VerifyDns.call(domain: @domain)

      if result
        redirect_to domains_path, notice: t("dashboard.domains.verify_dns.success")
      else
        redirect_to domains_path, alert: t("dashboard.domains.verify_dns.failure", target: Domain::CNAME_TARGET)
      end
    end

    private

    def set_domain
      @domain = current_account.domains.find(params[:id])
    end

    def domain_params
      params.require(:domain).permit(:name, :value, :domain_type)
    end

    # Only name is editable after creation — domain value is immutable
    def update_params
      params.require(:domain).permit(:name)
    end
  end
end
