# frozen_string_literal: true

module Dashboard
  class AttachmentsController < DashboardController
    before_action :authorize_attachment_access, only: [ :create, :destroy ]
    skip_before_action :authenticate_user!, only: [ :show ]
    skip_before_action :redirect_if_no_accounts, only: [ :show ]

    # Public-ish endpoint for serving images in emails
    def show
      @attachment = Attachment.find(params[:id])

      if @attachment.file.attached?
        redirect_to(url_for(@attachment.file), allow_other_host: true)
      else
        head(:not_found)
      end
    end

    # Upload attachment (used by GrapeJS asset manager)
    def create
      resource = resolve_resource
      return unless resource
      return if unsupported_article_image?

      @attachment = resource.attachments.new(
        account: Current.account,
        attachment_type: params[:attachment_type].presence || :image
      )

      @attachment.file.attach(params[:file])

      if @attachment.save
        render(json: {
          data: [ {
            src: attachment_url(@attachment),
            id: @attachment.id,
            name: @attachment.file.filename.to_s,
            alt: @attachment.file.filename.to_s
          } ]
        })
      else
        render(json: { error: @attachment.errors.full_messages }, status: :unprocessable_entity)
      end
    end

    def destroy
      @attachment = Current.account.attachments.find(params[:id])

      # Prevent deletion of images that are referenced in published templates
      if @attachment.referenced_in_published_content?
        return render(json: {
          error: I18n.t("errors.attachments.in_use")
        }, status: :unprocessable_entity)
      end

      @attachment.destroy
      head(:ok)
    end

    private

    def authorize_attachment_access
      if params[:resource_type] == "HelpCenter::Article"
        authorize(::HelpCenter::Article, :update?)
      else
        authorize(EmailTemplate, :update?)
      end
    end

    # Resolve the resource (EmailTemplate or EmailTemplateLayout) scoped to current account
    def resolve_resource
      allowed_types = {
        "EmailTemplate" => :email_templates,
        "EmailTemplateLayout" => :email_template_layouts,
        "HelpCenter::Article" => :help_center_articles
      }

      collection_name = allowed_types[params[:resource_type]]
      unless collection_name
        render(json: { error: I18n.t("errors.attachments.invalid_resource") }, status: :bad_request)
        return nil
      end

      resource = Current.account.public_send(collection_name).find_by(id: params[:resource_id])
      unless resource
        render(json: { error: I18n.t("errors.attachments.resource_not_found") }, status: :not_found)
        return nil
      end

      resource
    end

    def unsupported_article_image?
      return false unless params[:resource_type] == "HelpCenter::Article"
      return false unless (params[:attachment_type].presence || "image") == "image"
      return false unless params[:file]&.content_type == "image/svg+xml"

      render(json: { error: "Unsupported image format. Please upload JPG, PNG, GIF, or WEBP." }, status: :unprocessable_entity)
      true
    end
  end
end
