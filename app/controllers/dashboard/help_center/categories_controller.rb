# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class CategoriesController < DashboardController
      before_action :set_portals, only: %i[index create]
      before_action :set_category, only: %i[update destroy]

      def index
        authorize(::HelpCenter::Category)

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
        authorize(::HelpCenter::Category)

        portal = selected_portal
        name = category_params[:name].to_s.strip

        unless portal
          respond_to do |format|
            format.html { redirect_to(help_center_categories_path, alert: "Unable to create collection: no help center portal was found.") }
            format.json { render(json: { error: "Unable to create collection: no help center portal was found." }, status: :unprocessable_entity) }
          end
          return
        end

        if name.blank?
          respond_to do |format|
            format.html { redirect_to(help_center_categories_path, alert: "Unable to create collection: name can't be blank.") }
            format.json { render(json: { error: "Unable to create collection: name can't be blank." }, status: :unprocessable_entity) }
          end
          return
        end

        @category = portal.categories.build(
          account: current_account,
          status: :active,
          visibility: category_params[:visibility].presence&.to_sym || :everyone,
          ancestry: category_params[:parent_id].presence,
          image: category_params[:image]
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
          format.html { redirect_to(help_center_categories_path, notice: "Collection was successfully created.") }
          format.json { render(json: { id: @category.id, name: @category.name.presence || "Untitled" }) }
        end
      rescue ActiveRecord::RecordInvalid => e
        error_msg = "Unable to create collection: #{e.record.errors.full_messages.join(', ')}"
        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, alert: error_msg) }
          format.json { render(json: { error: error_msg }, status: :unprocessable_entity) }
        end
      rescue ActionController::ParameterMissing => e
        error_msg = "Unable to create collection: missing parameter - #{e.message}"
        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, alert: error_msg) }
          format.json { render(json: { error: error_msg }, status: :unprocessable_entity) }
        end
      rescue StandardError => e
        error_msg = "Unable to create collection: #{e.class} - #{e.message}"
        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, alert: error_msg) }
          format.json { render(json: { error: error_msg }, status: :unprocessable_entity) }
        end
      end

      def update
        authorize(@category)

        name = category_params[:name].to_s.strip

        if name.blank?
          respond_to do |format|
            format.html { redirect_to(help_center_categories_path, alert: "Unable to update collection: name can't be blank.") }
            format.json { render(json: { error: "Unable to update collection: name can't be blank." }, status: :unprocessable_entity) }
          end
          return
        end

        without_search_indexing do
          ActiveRecord::Base.transaction do
            update_attrs = {
              visibility: category_params[:visibility].presence&.to_sym || @category.visibility,
              ancestry: category_params[:parent_id].presence
            }
            update_attrs[:image] = category_params[:image] if category_params.key?(:image)
            @category.update!(update_attrs)

            locale = category_locale(@category.portal)
            translation = @category.translations.find_or_initialize_by(locale: locale)
            translation.update!(
              name: name,
              description: category_params[:description]
            )
          end
        end

        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, notice: "Collection was successfully updated.", status: :see_other) }
          format.json { render(json: { id: @category.id, name: @category.name.presence || "Untitled" }) }
        end
      rescue ActiveRecord::RecordInvalid => e
        error_msg = "Unable to update collection: #{e.record.errors.full_messages.join(', ')}"
        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, alert: error_msg, status: :see_other) }
          format.json { render(json: { error: error_msg }, status: :unprocessable_entity) }
        end
      rescue StandardError => e
        error_msg = "Unable to update collection: #{e.class} - #{e.message}"
        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, alert: error_msg, status: :see_other) }
          format.json { render(json: { error: error_msg }, status: :unprocessable_entity) }
        end
      end

      def destroy
        authorize(@category)
        @category.destroy!
        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, notice: "Collection was successfully deleted.", status: :see_other) }
          format.json { head(:no_content) }
        end
      rescue StandardError => e
        error_msg = "Unable to delete collection: #{e.message}"
        respond_to do |format|
          format.html { redirect_to(help_center_categories_path, alert: error_msg, status: :see_other) }
          format.json { render(json: { error: error_msg }, status: :unprocessable_entity) }
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

      def without_search_indexing(&)
        if defined?(Searchkick)
          Searchkick.callbacks(false, &)
        else
          yield
        end
      end

      def set_portals
        @portals = current_account.portals.includes(:translations).order(created_at: :desc)
      end

      def set_category
        @category = ::HelpCenter::Category
          .where(account: current_account)
          .left_joins(:translations)
          .find_by("help_center_categories.id::text = ? OR help_center_category_translations.slug = ?", params[:id].to_s, params[:id].to_s)

        raise(ActiveRecord::RecordNotFound) unless @category
      end

      def category_params
        params.expect(category: [ :name, :portal_id, :locale, :description, :parent_id, :visibility, :image ])
      end
    end
  end
end
