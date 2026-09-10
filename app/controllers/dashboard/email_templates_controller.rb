# frozen_string_literal: true

module Dashboard
  class EmailTemplatesController < DashboardController
    layout "email_builder", only: :edit
    before_action :set_email_template, only: %i[edit update publish discard_draft preview send_test variables copy_locale destroy]

    def index
      authorize(EmailTemplate)
      @email_templates = Current.account.email_templates.includes(:translations)
    end

    def new
      authorize(EmailTemplate)
      @email_template = EmailTemplate.new
    end

    def edit
      authorize(@email_template)
      @locale = params[:template_locale] || I18n.locale.to_s
      @layouts = Current.account.email_template_layouts

      I18n.with_locale(@locale) do
        # Initialize draft from published content if this is the first edit
        @email_template.initialize_draft!(locale: @locale)
        @email_template.translations.reload # Reload association so new locales appear in dropdown

        @draft_design = @email_template.draft_design || {}
        @draft_body = @email_template.draft_body || ""
        @has_unpublished_changes = @email_template.has_unpublished_changes?(locale: @locale)
        @template_variables = @email_template.variable_groups
      end
    end
    def create
      authorize(EmailTemplate)

      name = params.dig(:email_template, :name)
      template_type = params.dig(:email_template, :template_type)

      @email_template = EmailTemplates::Creator.call(
        account: Current.account,
        name: name,
        template_type: template_type
      )

      respond_to do |format|
        format.html { redirect_to(edit_email_template_path(@email_template), notice: "Template created successfully.") }
        format.json { render(json: { success: true, redirect_url: edit_email_template_path(@email_template) }) }
      end
    rescue StandardError => e
      respond_to do |format|
        format.html { redirect_to(email_templates_path, alert: e.message) }
        format.json { render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity) }
      end
    end

    # Save draft only — does NOT affect live template
    def update
      authorize(@email_template)
      locale = params[:template_locale] || I18n.locale.to_s

      I18n.with_locale(locale) do
        @email_template.save_draft!(
          draft_body_content: params.dig(:email_template, :draft_body),
          draft_design_content: params.dig(:email_template, :draft_design),
          draft_subject_content: params.dig(:email_template, :draft_subject),
          locale: locale
        )

        # Update non-translatable fields
        @email_template.update!(email_template_params) if email_template_params.present?
      end

      render(json: { success: true, message: I18n.t("dashboard.email_builder.draft_saved") })
    rescue ActiveRecord::RecordInvalid => e
      render(json: { success: false, errors: e.record.errors.full_messages }, status: :unprocessable_entity)
    end
    def destroy
      authorize(@email_template)

      @email_template.destroy!

      respond_to do |format|
        format.html { redirect_to(email_templates_path, notice: I18n.t("dashboard.email_builder.deleted")) }
        format.json { render(json: { success: true, message: I18n.t("dashboard.email_builder.deleted") }) }
      end
    rescue StandardError => e
      respond_to do |format|
        format.html { redirect_to(email_templates_path, alert: e.message) }
        format.json { render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity) }
      end
    end



    # Publish draft → live (explicit action with confirmation)
    def publish
      authorize(@email_template)
      locale = params[:template_locale] || I18n.locale.to_s

      @email_template.publish!(locale: locale)

      render(json: { success: true, message: I18n.t("dashboard.email_builder.published") })
    rescue StandardError => e
      render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity)
    end

    # Discard draft changes, reset to published version
    def discard_draft
      authorize(@email_template)
      locale = params[:template_locale] || I18n.locale.to_s

      @email_template.discard_draft!(locale: locale)

      render(json: { success: true, message: I18n.t("dashboard.email_builder.draft_discarded") })
    end

    # Preview compiled draft content with sample variables
    def preview
      authorize(@email_template)
      locale = params[:template_locale] || I18n.locale.to_s

      I18n.with_locale(locale) do
        draft_mjml = @email_template.draft_body
        layout_body = @email_template.email_template_layout&.body

        compiled_html = Emails::TemplateCompilerService.compile_with_layout(
          draft_mjml, layout_body: layout_body
        )

        # Render with sample variables for preview
        sample_vars = sample_variables_for(@email_template.template_type)
        rendered = Liquid::Template.parse(compiled_html).render(sample_vars)

        render(json: { html: rendered })
      end
    rescue StandardError => e
      render(json: { error: e.message }, status: :unprocessable_entity)
    end

    # Send test email to current user using draft content
    def send_test
      authorize(@email_template)
      locale = params[:template_locale] || I18n.locale.to_s

      I18n.with_locale(locale) do
        draft_mjml = @email_template.draft_body
        layout_body = @email_template.email_template_layout&.body

        compiled_html = Emails::TemplateCompilerService.compile_with_layout(
          draft_mjml, layout_body: layout_body
        )

        sample_vars = sample_variables_for(@email_template.template_type)
        rendered = Liquid::Template.parse(compiled_html).render(sample_vars)
        target_translation = @email_template.translations.find { |t| t.locale.to_s == locale.to_s }
        subject = target_translation&.draft_subject.presence || target_translation&.subject || @email_template.subject.presence || @email_template.name.titleize

        # Send test email to current user
        SystemMailer.test_template(
          to: current_user.email,
          subject: "[#{I18n.t('dashboard.email_builder.test_prefix')}] #{subject}",
          body: rendered
        ).deliver_later

        render(json: { success: true, message: I18n.t("dashboard.email_builder.test_sent", email: current_user.email) })
      end
    rescue StandardError => e
      render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity)
    end

    # Return available variables for this template type
    def variables
      authorize(@email_template)
      render(json: { variables: @email_template.variable_groups })
    end

    # Copy draft content from one locale to another
    def copy_locale
      authorize(@email_template, :update?)
      source_locale = params[:source_locale]
      target_locale = params[:target_locale]

      @email_template.copy_draft_locale!(from: source_locale, to: target_locale)

      render(json: { success: true, message: I18n.t("dashboard.email_builder.locale_copied", from: source_locale.upcase, to: target_locale.upcase) })
    rescue StandardError => e
      render(json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity)
    end

    private

    def set_email_template
      @email_template = Current.account.email_templates.find(params[:id])
    end

    def email_template_params
      params.expect(email_template: [ :email_template_layout_id, :status ])
    rescue ActionController::ParameterMissing
      {}
    end

    # Sample variables for preview and test email rendering
    def sample_variables_for(template_name)
      base = {
        "account" => { "name" => Current.account.name }
      }

      case template_name
      when "conversation_reply"
        base.merge(
          "customer" => { "name" => "John Doe", "email" => "john@example.com" },
          "agent"    => { "name" => current_user.display_name || "Agent", "email" => current_user.email },
          "message"  => { "content" => I18n.t("dashboard.email_builder.sample.message_content") },
          "conversation" => { "subject" => I18n.t("dashboard.email_builder.sample.conversation_subject"), "identifier" => "CONV-1234" },
          "inbox"    => { "name" => "Support" }
        )
      when "agent_notification"
        base.merge(
          "agent" => { "name" => current_user.display_name || "Agent", "email" => current_user.email },
          "event" => { "title" => I18n.t("dashboard.email_builder.sample.event_title"), "description" => I18n.t("dashboard.email_builder.sample.event_description") },
          "conversation" => { "identifier" => "CONV-1234" },
          "inbox" => { "name" => "Support" }
        )
      when "welcome_email"
        base.merge(
          "user" => { "name" => current_user.display_name || "User", "email" => current_user.email }
        )
      when "password_reset"
        base.merge(
          "user"       => { "name" => current_user.display_name || "User", "email" => current_user.email },
          "reset_link" => "#"
        )
      when "email_verification"
        base.merge(
          "user"              => { "name" => current_user.display_name || "User", "email" => current_user.email },
          "verification_link" => "#"
        )
      when "team_invitation"
        base.merge(
          "inviter"     => { "name" => current_user.display_name || "Admin" },
          "team"        => { "name" => "Support Team" },
          "invite_link" => "#"
        )
      when "csat_survey"
        base.merge(
          "customer"     => { "name" => "John Doe", "email" => "john@example.com" },
          "agent"        => { "name" => current_user.display_name || "Agent", "email" => current_user.email },
          "conversation" => { "subject" => I18n.t("dashboard.email_builder.sample.conversation_subject", default: "Sample Subject"), "identifier" => "CONV-1234" },
          "inbox"        => { "name" => "Support" },
          "csat"         => { "survey_url" => "#" }
        )
      else
        base
      end
    end
  end
end
