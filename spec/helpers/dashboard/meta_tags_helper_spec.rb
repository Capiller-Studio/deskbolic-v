# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::MetaTagsHelper, type: :helper do
  describe '#meta_title, #meta_description, #meta_keywords' do
    it 'returns fallback i18n title when content_for is not set' do
      expect(helper.meta_title).to eq('Capiller Rely')
    end

    it 'returns custom value when content_for is set' do
      helper.content_for(:meta_title, 'Custom Title')
      helper.content_for(:meta_description, 'Custom Description')
      helper.content_for(:meta_keywords, 'Custom Keywords')

      expect(helper.meta_title).to eq('Custom Title')
      expect(helper.meta_description).to eq('Custom Description')
      expect(helper.meta_keywords).to eq('Custom Keywords')
    end
  end

  describe '#meta_image' do
    it 'resolves image url when content_for is not set' do
      expect(helper).to receive(:image_url).with('icon.png').and_return('http://test.host/images/icon.png')
      expect(helper.meta_image).to eq('http://test.host/images/icon.png')
    end

    it 'returns direct url if starts with http' do
      helper.content_for(:meta_image, 'https://example.com/logo.png')
      expect(helper.meta_image).to eq('https://example.com/logo.png')
    end
  end
end
