# frozen_string_literal: true

module Dashboard
  module HelpCenter
    class ArticlesController < DashboardController
      before_action :set_article, only: %i[edit update publish discard_draft copy_locale]

      def edit
        authorize @article
        @locale = params[:article_locale] || I18n.locale.to_s

        I18n.with_locale(@locale) do
          # Initialize draft from published content if this is the first edit
          @article.initialize_draft!(locale: @locale)
          @article.translations.reload # Reload association so new locales appear

          @draft_content = @article.draft_content || ""
          @draft_title = @article.translations.find { |t| t.locale.to_s == @locale }&.draft_title || @article.title || ""
          @has_unpublished_changes = @article.has_unpublished_changes?(locale: @locale)
        end
      end

      # Save draft only — does NOT affect live article
      def update
        authorize @article
        locale = params[:article_locale] || I18n.locale.to_s

        I18n.with_locale(locale) do
          @article.save_draft!(
            draft_content_content: params.dig(:article, :draft_content),
            draft_title_content: params.dig(:article, :draft_title),
            locale: locale
          )

          # Update non-translatable fields if any exist
          @article.update!(article_params) if article_params.present?
        end

        render json: { success: true, message: I18n.t("dashboard.articles.draft_saved", default: "Draft saved successfully.") }
      rescue ActiveRecord::RecordInvalid => e
        render json: { success: false, errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # Publish draft → live
      def publish
        authorize @article
        locale = params[:article_locale] || I18n.locale.to_s

        @article.publish!(locale: locale)

        render json: { success: true, message: I18n.t("dashboard.articles.published", default: "Article published successfully.") }
      rescue StandardError => e
        render json: { success: false, errors: [e.message] }, status: :unprocessable_entity
      end

      # Discard draft changes, reset to published version
      def discard_draft
        authorize @article
        locale = params[:article_locale] || I18n.locale.to_s

        @article.discard_draft!(locale: locale)

        render json: { success: true, message: I18n.t("dashboard.articles.draft_discarded", default: "Draft discarded successfully.") }
      end

      # Copy draft content from one locale to another
      def copy_locale
        authorize @article, :update?
        source_locale = params[:source_locale]
        target_locale = params[:target_locale]

        @article.copy_draft_locale!(from: source_locale, to: target_locale)

        render json: { success: true, message: I18n.t("dashboard.articles.locale_copied", default: "Locale content copied successfully.") }
      rescue StandardError => e
        render json: { success: false, errors: [e.message] }, status: :unprocessable_entity
      end

      private

      def set_article
        @article = ::HelpCenter::Article.where(account: current_account).find(params[:id])
      end

      def article_params
        params.require(:article).permit(:status, :visibility, :article_type, :position)
      rescue ActionController::ParameterMissing
        {}
      end
    end
  end
end
