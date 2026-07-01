# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class CategoriesController < DashboardController
      before_action :set_portals, only: %i[index create]

      def index
        authorize ::HelpCenter::Category

        @query = params[:q].to_s.strip
        @portal_id = params[:portal_id].presence
        @selected_portal = if @portal_id.present?
          @portals.find { |p| p.id.to_s == @portal_id }
        else
          @portals.first
        end

        categories = ::HelpCenter::Category
          .where(account: current_account)
          .includes(:translations, :portal)
          .order(:position, :created_at)

        categories = categories.where(portal_id: @portal_id) if @portal_id.present?

        if @query.present?
          categories = categories.left_joins(:translations)
                                 .where("help_center_category_translations.name ILIKE :query", query: "%#{@query}%")
                                 .distinct
        end

        @pagy, @categories = pagy(categories, limit: 20)
      end

      def create
        authorize ::HelpCenter::Category

        portal = selected_portal
        name = category_params[:name].to_s.strip

        unless portal
          respond_to do |format|
            format.html { redirect_to help_center_categories_path, alert: "Unable to create collection: no help center portal was found." }
            format.json { render json: { error: "Unable to create collection: no help center portal was found." }, status: :unprocessable_entity }
          end
          return
        end

        if name.blank?
          respond_to do |format|
            format.html { redirect_to help_center_categories_path, alert: "Unable to create collection: name can't be blank." }
            format.json { render json: { error: "Unable to create collection: name can't be blank." }, status: :unprocessable_entity }
          end
          return
        end

        @category = portal.categories.build(
          account: current_account,
          status: :active,
          visibility: category_params[:visibility].presence&.to_sym || :everyone,
          ancestry: category_params[:parent_id].presence
        )

        without_search_indexing do
          ActiveRecord::Base.transaction do
            @category.translations.build(
              locale: category_locale(portal),
              name: name,
              description: category_params[:description]
            )

            @category.save!
          end
        end

        respond_to do |format|
          format.html { redirect_to help_center_categories_path, notice: "Collection was successfully created." }
          format.json { render json: { id: @category.id, name: @category.name.presence || "Untitled" } }
        end
      rescue ActiveRecord::RecordInvalid => e
        error_msg = "Unable to create collection: #{e.record.errors.full_messages.join(', ')}"
        respond_to do |format|
          format.html { redirect_to help_center_categories_path, alert: error_msg }
          format.json { render json: { error: error_msg }, status: :unprocessable_entity }
        end
      rescue ActionController::ParameterMissing => e
        error_msg = "Unable to create collection: missing parameter - #{e.message}"
        respond_to do |format|
          format.html { redirect_to help_center_categories_path, alert: error_msg }
          format.json { render json: { error: error_msg }, status: :unprocessable_entity }
        end
      rescue StandardError => e
        error_msg = "Unable to create collection: #{e.class} - #{e.message}"
        respond_to do |format|
          format.html { redirect_to help_center_categories_path, alert: error_msg }
          format.json { render json: { error: error_msg }, status: :unprocessable_entity }
        end
      end

      private

      def selected_portal
        if category_params[:portal_id].present?
          current_account.portals.find_by(id: category_params[:portal_id])
        else
          current_account.portals.first
        end
      end

      def category_locale(portal)
        category_params[:locale].presence || portal.default_locale.presence || I18n.locale.to_s
      end

      def without_search_indexing(&block)
        if defined?(Searchkick)
          Searchkick.callbacks(false, &block)
        else
          yield
        end
      end

      def set_portals
        @portals = current_account.portals.includes(:translations).order(created_at: :desc)
      end

      def category_params
        params.require(:category).permit(:name, :portal_id, :locale, :description, :parent_id, :visibility)
      end
    end
  end
end
