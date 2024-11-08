# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  module MetaTagsHelper
    DEFAULT_META_IMAGE = "icon.png"

    def meta_title
      content_for?(:meta_title) ? content_for(:meta_title) : I18n.t("meta.title")
    end

    def meta_description
      content_for?(:meta_description) ? content_for(:meta_description) : I18n.t("meta.description")
    end

    def meta_keywords
      content_for?(:meta_keywords) ? content_for(:meta_keywords) : I18n.t("meta.keywords")
    end

    def meta_image
      meta_image = (content_for?(:meta_image) ? content_for(:meta_image) : DEFAULT_META_IMAGE)
      meta_image.starts_with?("http") ? meta_image : image_url(meta_image)
    end
  end
end
