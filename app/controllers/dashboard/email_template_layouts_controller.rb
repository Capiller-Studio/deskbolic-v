# frozen_string_literal: true

module Dashboard
  class EmailTemplateLayoutsController < DashboardController
    before_action :set_email_template_layout, only: %i[edit update publish discard_draft preview copy_locale]

    def index
      authorize EmailTemplateLayout
      @email_template_layouts = Current.account.email_template_layouts.includes(:translations)
    end

    def edit
      authorize @email_template_layout
      @locale = params[:template_locale] || I18n.locale.to_s

      I18n.with_locale(@locale) do
        @email_template_layout.initialize_draft!(locale: @locale)
        @email_template_layout.translations.reload # Reload association so new locales appear in dropdown

        @draft_design = @email_template_layout.draft_design || {}
        @draft_body = @email_template_layout.draft_body || ""
        @has_unpublished_changes = @email_template_layout.has_unpublished_changes?(locale: @locale)
      end
    end

    # Save draft only
    def update
      authorize @email_template_layout
      locale = params[:template_locale] || I18n.locale.to_s

      I18n.with_locale(locale) do
        @email_template_layout.save_draft!(
          draft_body_content: params.dig(:email_template_layout, :draft_body),
          draft_design_content: params.dig(:email_template_layout, :draft_design),
          locale: locale
        )
      end

      render json: { success: true, message: I18n.t("dashboard.email_builder.draft_saved") }
    rescue ActiveRecord::RecordInvalid => e
      render json: { success: false, errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    # Publish draft → live
    def publish
      authorize @email_template_layout
      locale = params[:template_locale] || I18n.locale.to_s

      @email_template_layout.publish!(locale: locale)

      render json: { success: true, message: I18n.t("dashboard.email_builder.published") }
    rescue StandardError => e
      render json: { success: false, errors: [e.message] }, status: :unprocessable_entity
    end

    # Discard draft
    def discard_draft
      authorize @email_template_layout
      locale = params[:template_locale] || I18n.locale.to_s

      @email_template_layout.discard_draft!(locale: locale)

      render json: { success: true, message: I18n.t("dashboard.email_builder.draft_discarded") }
    end

    # Preview compiled draft
    def preview
      authorize @email_template_layout
      locale = params[:template_locale] || I18n.locale.to_s

      I18n.with_locale(locale) do
        compiled_html = Emails::TemplateCompilerService.compile(@email_template_layout.draft_body)
        render json: { html: compiled_html }
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # Copy draft content from one locale to another
    def copy_locale
      authorize @email_template_layout, :update?
      source_locale = params[:source_locale]
      target_locale = params[:target_locale]

      @email_template_layout.copy_draft_locale!(from: source_locale, to: target_locale)

      render json: { success: true, message: I18n.t("dashboard.email_builder.locale_copied", from: source_locale.upcase, to: target_locale.upcase) }
    rescue StandardError => e
      render json: { success: false, errors: [e.message] }, status: :unprocessable_entity
    end

    private

    def set_email_template_layout
      @email_template_layout = Current.account.email_template_layouts.find(params[:id])
    end
  end
end
