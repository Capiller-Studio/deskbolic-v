# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utilities::AttachmentTypeHelpers do
  describe ".image?" do
    it "returns true for standard image MIME types" do
      expect(described_class.image?("image/png")).to be true
      expect(described_class.image?("image/jpeg")).to be true
      expect(described_class.image?("image/webp")).to be true
      expect(described_class.image?("image/gif")).to be true
      expect(described_class.image?("image/svg+xml")).to be true
    end

    it "returns false for non-image MIME types" do
      expect(described_class.image?("audio/mp4")).to be false
      expect(described_class.image?("video/mp4")).to be false
      expect(described_class.image?("application/pdf")).to be false
    end
  end

  describe ".video?" do
    it "returns true for standard video MIME types" do
      expect(described_class.video?("video/mp4")).to be true
      expect(described_class.video?("video/webm")).to be true
      expect(described_class.video?("video/quicktime")).to be true
    end

    it "returns false for non-video MIME types" do
      expect(described_class.video?("audio/mp4")).to be false
      expect(described_class.video?("image/png")).to be false
      expect(described_class.video?("application/pdf")).to be false
    end
  end

  describe ".audio?" do
    it "returns true for standard audio MIME types" do
      expect(described_class.audio?("audio/mp4")).to be true
      expect(described_class.audio?("audio/webm")).to be true
      expect(described_class.audio?("audio/wav")).to be true
      expect(described_class.audio?("audio/ogg")).to be true
      expect(described_class.audio?("audio/aac")).to be true
    end

    it "returns false for non-audio MIME types" do
      expect(described_class.audio?("video/mp4")).to be false
      expect(described_class.audio?("image/png")).to be false
      expect(described_class.audio?("application/pdf")).to be false
    end
  end

  describe ".attachment_type" do
    it "maps image MIME types to :image" do
      expect(described_class.attachment_type("image/png")).to eq(:image)
      expect(described_class.attachment_type("image/jpeg")).to eq(:image)
    end

    it "maps video MIME types to :video" do
      expect(described_class.attachment_type("video/mp4")).to eq(:video)
    end

    it "maps audio MIME types to :audio" do
      expect(described_class.attachment_type("audio/mp4")).to eq(:audio)
      expect(described_class.attachment_type("audio/webm")).to eq(:audio)
      expect(described_class.attachment_type("audio/wav")).to eq(:audio)
    end

    it "defaults other MIME types to :file" do
      expect(described_class.attachment_type("application/pdf")).to eq(:file)
      expect(described_class.attachment_type("application/zip")).to eq(:file)
      expect(described_class.attachment_type("text/plain")).to eq(:file)
      expect(described_class.attachment_type("")).to eq(:file)
      expect(described_class.attachment_type(nil)).to eq(:file)
    end
  end
end
