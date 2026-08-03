# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class PortalsController < DashboardController
      PRIMARY_COLORS = ["#2F3FD6", "#6E2DE2", "#5850EC", "#16A34A", "#059669", "#EA580C", "#DC2626", "#DB2777", "#0D9488"].freeze
      SECONDARY_COLORS = ["#B8C5FF", "#D8C4FB", "#C4B5FD", "#A7F3D0", "#99F6E4", "#FED7AA", "#FCA5A5", "#F9A8D4", "#A7F3F0"].freeze
      THEME_OPTIONS = [
        ["light", "Light", "light_theme.svg"],
        ["dark", "Dark", "dark_theme.svg"],
        ["system", "System", "theme.svg"]
      ].freeze
      HERO_STYLE_OPTIONS = [
        ["plain", "Plain"],
        ["gradient", "Gradient"],
        ["image", "Image"]
      ].freeze
      LAYOUT_OPTIONS = [
        ["grid", "Grid Layout"],
        ["list", "List Layout"]
      ].freeze

      before_action :set_available_domains, only: %i[new create edit update]

      def index
        authorize ::HelpCenter::Portal
        @portals = current_account.portals.includes(:domain).with_attached_hero_image.order(created_at: :desc)
      end

      def new
        @portal = ::HelpCenter::Portal.new(default_locale: I18n.default_locale.to_s, locales: [I18n.default_locale.to_s])
        authorize @portal
        prepare_form_state
      end

      def edit
        @portal = current_account.portals.find(params[:id])
        authorize @portal
        @available_domains << @portal.domain
        prepare_form_state
      end

      def update
        @portal = current_account.portals.find(params[:id])
        authorize @portal
        @portal.domain = selected_domain || @portal.domain
        @portal.locales = submitted_locales
        @portal.default_locale = selected_default_locale
        @portal.ui_configurations = ui_configurations
        if @portal.domain.blank?
          @portal.errors.add(:domain, "must be selected")
          set_available_domains
          prepare_form_state
          render :edit, status: :unprocessable_entity
          return
        end

        if @portal.update(portal_attributes)
          redirect_to help_center_portals_path, notice: "Help Center updated successfully."
        else
          set_available_domains
          prepare_form_state
          render :edit, status: :unprocessable_entity
        end
      end

      def create
        @portal = current_account.portals.build(portal_attributes)
        authorize @portal

        @portal.locales = submitted_locales
        @portal.default_locale = selected_default_locale
        @portal.configurations = default_configurations
        @portal.ui_configurations = ui_configurations

        begin
          ActiveRecord::Base.transaction do
            if portal_params[:domain_type] == "subdomain"
              domain = ::Domains::CreateSubdomain.call(
                account: current_account,
                slug: portal_params[:subdomain_slug],
                name: @portal.name
              )
              @portal.domain = domain
            else
              unless current_account.feature_enabled?(:custom_domains)
                @portal.errors.add(:domain, I18n.t("dashboard.portals.custom_domain_not_supported", default: "Custom domains are not supported on your current plan."))
                raise ActiveRecord::RecordInvalid, @portal
              end

              @portal.domain = selected_domain
              if selected_domain.blank?
                @portal.errors.add(:domain, I18n.t("errors.messages.blank", default: "can't be blank"))
                raise ActiveRecord::RecordInvalid, @portal
              end
            end

            @portal.save!
          end

          redirect_to help_center_portals_path, notice: I18n.t("dashboard.portals.created_successfully", default: "Help Center created successfully.")
        rescue ActiveRecord::RecordInvalid => e
          if e.record.is_a?(Domain)
            e.record.errors.each do |error|
              @portal.errors.add(:base, I18n.t("dashboard.portals.subdomain_error", msg: error.full_message, default: "Subdomain %{msg}"))
            end
          end

          set_available_domains
          prepare_form_state
          render :new, status: :unprocessable_entity
        end
      end

      private

      def default_configurations
        { "custom_css" => "" }
      end

      def portal_attributes
        portal_params.slice(:name, :logo, :favicon, :social_share_image, :hero_image)
      end

      def selected_domain
        @selected_domain ||= @available_domains.find { |domain| domain.id == portal_params[:domain_id] }
      end

      def selected_default_locale
        default_locale = portal_params[:default_locale].presence || I18n.default_locale.to_s
        submitted_locales.include?(default_locale) ? default_locale : submitted_locales.first
      end

      def submitted_locales
        @submitted_locales ||= begin
          locales = Array(portal_params[:locales]).reject(&:blank?)
          locales = [I18n.default_locale.to_s] if locales.blank?
          supported_locales = locales & Core::SUPPORTED_LOCALES.map(&:to_s)
          supported_locales.presence || [I18n.default_locale.to_s]
        end
      end

      def ui_configurations
        (portal_params[:ui_configurations] || {}).to_h.compact_blank
      end

      def set_available_domains
        @available_domains = current_account.domains.includes(:portal).select { |domain| domain.portal.blank? }
      end

      def prepare_form_state
        @selected_ui = @portal.ui_configurations || {}
        @selected_primary = @selected_ui["primary_color"].presence || "#5850EC"
        @selected_secondary = @selected_ui["secondary_color"].presence || "#FCA5A5"
        @selected_theme = @selected_ui["theme_preference"].presence || "light"
        @selected_hero = @selected_ui["hero_style"].presence || "image"
        @selected_layout = @selected_ui["category_layout"].presence || "grid"
        @selected_locales = Array(@portal.locales.presence || [I18n.default_locale.to_s])
        @primary_colors = PRIMARY_COLORS
        @secondary_colors = SECONDARY_COLORS
        @theme_options = THEME_OPTIONS
        @hero_style_options = HERO_STYLE_OPTIONS
        @layout_options = LAYOUT_OPTIONS
      end

      def portal_params
        params.fetch(:help_center_portal, ActionController::Parameters.new).permit(
          :name,
          :logo,
          :favicon,
          :social_share_image,
          :hero_image,
          :domain_id,
          :domain_type,
          :subdomain_slug,
          :default_locale,
          locales: [],
          ui_configurations: [
            :theme_preference,
            :primary_color,
            :secondary_color,
            :hero_style,
            :category_layout
          ]
        )
      end
    end
  end
end
