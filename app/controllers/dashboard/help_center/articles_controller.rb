# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class ArticlesController < DashboardController
      before_action :set_article, only: %i[show edit update publish discard_draft copy_locale destroy]
      before_action :set_article_context, only: %i[index new create show edit update]

      def index
        authorize(::HelpCenter::Article)

        @query = params[:q].to_s.strip
        @status = params[:status].presence
        @visibility = params[:visibility].presence
        @portal_id = params[:portal_id].presence
        @category_id = params[:category_id].presence
        @columns = selected_columns

        articles = ::HelpCenter::Article
          .where(account: current_account)
          .includes(:translations, :portal, :primary_category, categories: :translations)
          .order(updated_at: :desc)

        articles = articles.where(status: @status) if @status.present? && ::HelpCenter::Article.statuses.key?(@status)
        articles = articles.where(visibility: @visibility) if @visibility.present? && ::HelpCenter::Article.visibilities.key?(@visibility)
        articles = articles.where(portal_id: @portal_id) if @portal_id.present?

        if @category_id.present?
          articles = articles.joins(:category_resources).where(help_center_category_resources: { category_id: @category_id })
        end

        if @query.present?
          articles = articles.left_joins(:translations)
                             .where("help_center_article_translations.title ILIKE :query OR help_center_article_translations.content ILIKE :query", query: "%#{@query}%")
                             .distinct
        end

        @pagy, @articles = pagy(articles, limit: 20)
      end

      def show
        authorize(@article)
        @locale = params[:article_locale].presence || default_article_locale(@article)
      end

      def new
        authorize(::HelpCenter::Article)
        @article = ::HelpCenter::Article.new(
          account: current_account,
          portal: @selected_portal,
          author: current_user,
          status: :draft,
          visibility: :everyone,
          article_type: :standard,
          configurations: default_configurations
        )
        build_default_translation(@article)
      end

      def edit
        authorize(@article)
        @locale = params[:article_locale].presence || default_article_locale(@article)
        build_default_translation(@article, locale: @locale)
        return unless request.format.json?

        I18n.with_locale(@locale) do
          # Initialize draft from published content if this is the first edit
          @article.initialize_draft!(locale: @locale)
          @article.translations.reload # Reload association so new locales appear

          @draft_content = @article.draft_content || ""
          @draft_title = @article.translations.find { |t| t.locale.to_s == @locale }&.draft_title || @article.title || ""
          @has_unpublished_changes = @article.has_unpublished_changes?(locale: @locale)
        end
      end
      def create
        authorize(::HelpCenter::Article)
        return if unsupported_banner_image?

        status_value = params[:publish].present? ? :published : :draft

        @article = ::HelpCenter::Article.new(normalized_article_params)
        @article.account = current_account
        @article.author = current_user
        @article.status = status_value

        ActiveRecord::Base.transaction do
          @article.save!
          sync_article_relationships(@article)
        end

        respond_to do |format|
          format.json { render(json: { success: true, message: "Article saved.", article_id: @article.id }) }
          format.html do
            if status_value == :published
              redirect_to(help_center_article_path(id: @article.id), notice: "Article was published successfully.")
            else
              redirect_to(help_center_article_path(id: @article.id), notice: "Article was saved as draft.")
            end
          end
        end
      rescue ActiveRecord::RecordInvalid
        respond_to do |format|
          format.json { render(json: { success: false, errors: @article.errors.full_messages }, status: :unprocessable_entity) }
          format.html do
            set_article_context
            build_default_translation(@article)
            flash.now[:alert] = "Unable to create article. Please check the fields and try again."
            render(:new, status: :unprocessable_entity)
          end
        end
      rescue StandardError => e
        respond_to do |format|
          format.json { render(json: { success: false, errors: [ e.message ] }, status: :internal_server_error) }
          format.html { raise }
        end
      end


      def update
        authorize(@article)
        return if unsupported_banner_image?

        respond_to do |format|
          format.json do
            # JSON draft save from the Tiptap editor or UI updates

            if params.dig(:article).present? && params.dig(:article).key?(:related_article_ids)
              sync_related_articles(@article)
            end

            if params.dig(:article, :translations_attributes, :"0").present?
              locale = params[:article_locale] || I18n.locale.to_s
              translation = @article.translations.find_or_initialize_by(locale: locale)

              draft_attrs = params.dig(:article, :translations_attributes, :"0") || {}
              translation.draft_title   = draft_attrs[:draft_title]   if draft_attrs.key?(:draft_title)
              translation.draft_content = draft_attrs[:draft_content] if draft_attrs.key?(:draft_content)
              translation.save!
            end

            render(json: { success: true, message: I18n.t("dashboard.articles.draft_saved", default: "Draft saved."), article_id: @article.id })
          rescue StandardError => e
            render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity)
          end

          format.html do
            if params[:publish].present?
              ActiveRecord::Base.transaction do
                @article.update!(normalized_article_params.merge(status: :published))
                sync_article_relationships(@article)
              end
              redirect_to(help_center_article_path(id: @article.id), notice: "Article was published successfully.")
            else
              ActiveRecord::Base.transaction do
                @article.update!(normalized_article_params.merge(status: :draft))
                sync_article_relationships(@article)
              end
              redirect_to(help_center_article_path(id: @article.id), notice: "Article was saved as draft.")
            end
          rescue ActiveRecord::RecordInvalid
            set_article_context
            build_default_translation(@article)
            flash.now[:alert] = "Unable to save article. Please check the fields and try again."
            render(:edit, status: :unprocessable_entity)
          end
        end
      end

      # Publish draft → live
      def publish
        authorize(@article)
        locale = params[:article_locale] || I18n.locale.to_s

        @article.publish!(locale: locale)

        render(json: { success: true, message: I18n.t("dashboard.articles.published", default: "Article published successfully.") })
      rescue StandardError => e
        render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity)
      end

      # Discard draft changes, reset to published version
      def discard_draft
        authorize(@article)
        locale = params[:article_locale] || I18n.locale.to_s

        @article.discard_draft!(locale: locale)

        render(json: { success: true, message: I18n.t("dashboard.articles.draft_discarded", default: "Draft discarded successfully.") })
      end

      def destroy
        authorize(@article)
        @article.destroy!
        respond_to do |format|
          format.html { redirect_to(help_center_articles_path, notice: "Article was successfully deleted.", status: :see_other) }
          format.json { head(:no_content) }
        end
      rescue StandardError => e
        error_msg = "Unable to delete article: #{e.message}"
        respond_to do |format|
          format.html { redirect_to(help_center_articles_path, alert: error_msg, status: :see_other) }
          format.json { render(json: { error: error_msg }, status: :unprocessable_entity) }
        end
      end

      def reorder
        authorize(::HelpCenter::Article)
        ordered_ids = params[:ordered_ids]

        articles = ::HelpCenter::Article.where(account: current_account, id: ordered_ids)

        ordered_ids.each_with_index do |id, index|
          articles.where(id: id).update_all(position: index)
        end

        head(:ok)
      end

      # Copy draft content from one locale to another
      def copy_locale
        authorize(@article, :update?)
        source_locale = params[:source_locale]
        target_locale = params[:target_locale]
        @article.copy_draft_locale!(from: source_locale, to: target_locale)
        translation = @article.translations.find_by(locale: target_locale)

        render(json: {
          success: true,
          message: I18n.t("dashboard.articles.locale_copied", default: "Locale content copied successfully."),
          draft_title: translation&.draft_title || "",
          draft_content: translation&.draft_content || ""
        })
      rescue StandardError => e
        render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity)
      end

      private

      def set_article
        @article = ::HelpCenter::Article
          .where(account: current_account)
          .includes(:translations, :portal, :primary_category, :categories, :related_articles)
          .joins(:translations)
          .find_by("help_center_articles.id::text = ? OR help_center_article_translations.slug = ?", params[:id], params[:id])

        raise(ActiveRecord::RecordNotFound) unless @article
      end

      def set_article_context
        @portals = current_account.portals.includes(:translations).order(created_at: :desc)
        @selected_portal = if params.dig(:article, :portal_id).present?
          @portals.find { |portal| portal.id.to_s == params.dig(:article, :portal_id).to_s }
        elsif @article&.portal
          @article.portal
        else
          @portals.first
        end

        @categories = ::HelpCenter::Category
          .where(account: current_account)
          .includes(:translations)
          .order(:position, :created_at)

        @article_options = ::HelpCenter::Article
          .where(account: current_account)
          .includes(:translations)
          .order(updated_at: :desc)
        @article_options = @article_options.where.not(id: @article.id) if @article&.persisted?
      end

      def article_params
        permitted = [
          :primary_category_id,
          :status,
          :article_type,
          :visibility,
          :position,
          :banner_image,
          { images: [], category_ids: [], related_article_ids: [] },
          configurations: %i[external_url show_table_of_contents estimated_read_time],
          translations_attributes: %i[
            id locale title slug content meta_title meta_description meta_keywords
            search_excerpt draft_title draft_content _destroy
          ]
        ]
        permitted << :portal_id unless @article&.persisted?
        params.expect(article: [ *permitted ])
      rescue ActionController::ParameterMissing
        {}
      end

      def normalized_article_params
        attrs = article_params.to_h
        normalize_configurations(attrs)
        normalize_translations(attrs)
        match_existing_translations(attrs)
        attrs
      end

      def normalize_configurations(attrs)
        attrs["configurations"] ||= {}
        attrs["configurations"]["show_table_of_contents"] = ActiveModel::Type::Boolean.new.cast(attrs["configurations"]["show_table_of_contents"])
        attrs["configurations"]["estimated_read_time"] = attrs["configurations"]["estimated_read_time"].presence&.to_i
        attrs["configurations"].compact!
      end

      def normalize_translations(attrs)
        return if attrs["translations_attributes"].blank?

        attrs["translations_attributes"].each_value do |translation|
          keywords = translation["meta_keywords"]
          translation["meta_keywords"] = keywords.to_s.split(",").map(&:strip).compact_blank

          if params[:publish].present?
            translation["draft_title"] = translation["title"] if translation.key?("title")
            translation["draft_content"] = translation["content"] if translation.key?("content")
          else
            translation["draft_title"] = translation.delete("title") if translation.key?("title")
            translation["draft_content"] = translation.delete("content") if translation.key?("content")
          end
        end
      end

      def match_existing_translations(attrs)
        return unless @article&.persisted?
        return if attrs["translations_attributes"].blank?

        attrs["translations_attributes"].each_value do |translation|
          next if translation["id"].present?

          locale = translation["locale"].presence || default_article_locale(@article)
          existing_translation = @article.translations.find { |item| item.locale.to_s == locale.to_s }
          translation["id"] = existing_translation.id if existing_translation
        end
      end

      def sync_article_relationships(article)
        sync_categories(article)
        sync_related_articles(article)
      end

      def sync_categories(article)
        category_ids = Array(params.dig(:article, :category_ids)).compact_blank
        category_ids << article.primary_category_id if article.primary_category_id.present?
        allowed_ids = ::HelpCenter::Category.where(account: current_account, id: category_ids).pluck(:id).map(&:to_s)

        article.category_resources.where.not(category_id: allowed_ids).destroy_all
        allowed_ids.each_with_index do |category_id, index|
          article.category_resources.find_or_initialize_by(category_id: category_id).tap do |resource|
            resource.position = params.dig(:article, :category_resource_position).presence || article.position || index
            resource.save!
          end
        end
      end

      def sync_related_articles(article)
        related_article_ids = Array(params.dig(:article, :related_article_ids)).compact_blank - [ article.id.to_s ]
        allowed_ids = ::HelpCenter::Article.where(account: current_account, id: related_article_ids).pluck(:id).map(&:to_s)

        article.related_resources
               .where(linked_resource_type: "HelpCenter::Article")
               .where.not(linked_resource_id: allowed_ids)
               .destroy_all

        allowed_ids.each do |related_article_id|
          article.related_resources.find_or_create_by!(
            linked_resource_id: related_article_id,
            linked_resource_type: "HelpCenter::Article"
          )
        end
      end

      def build_default_translation(article, locale: nil)
        locale ||= default_article_locale(article)
        article.translations.build(locale: locale) unless article.translations.any? { |translation| translation.locale.to_s == locale.to_s }
      end

      def default_article_locale(article)
        article.portal&.default_locale.presence || @selected_portal&.default_locale.presence || I18n.locale.to_s
      end

      def default_configurations
        {
          "show_table_of_contents" => true,
          "estimated_read_time" => nil,
          "external_url" => nil
        }
      end

      def selected_columns
        allowed = %w[title last_edit status collection]
        selected = Array(params[:columns]).presence || allowed
        selected & allowed
      end

      def unsupported_banner_image?
        banner_image = params.dig(:article, :banner_image)
        return false unless banner_image&.content_type == "image/svg+xml"

        respond_to do |format|
          format.json { render(json: { success: false, errors: [ "Unsupported banner image format. Please upload JPG, PNG, GIF, or WEBP." ] }, status: :unprocessable_entity) }
          format.html do
            set_article_context
            build_default_translation(@article || ::HelpCenter::Article.new(account: current_account, portal: @selected_portal, author: current_user))
            flash.now[:alert] = "Unsupported banner image format. Please upload JPG, PNG, GIF, or WEBP."
            render((@article&.persisted? ? :edit : :new), status: :unprocessable_entity)
          end
        end
        true
      end
    end
  end
end
