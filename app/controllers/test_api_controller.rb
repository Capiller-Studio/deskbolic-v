# frozen_string_literal: true

class TestApiController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  def identity_endpoint
    render json: {
      success: true,
      message: "This is a mock response from the development Test API.",
      received_method: request.method,
      received_headers: request.headers.to_h.select { |k, _| k.start_with?("HTTP_") || k == "CONTENT_TYPE" },
      received_params: params.except(:controller, :action).to_unsafe_h,
      mock_identity: {
        first_name: "Alex",
        last_name: "Tester",
        identifier: params[:identifier] || "default_test_id",
        tags: ["premium", "beta_tester"],
        company: "Acme Corp"
      }
    }
  end

  def custom_channel_endpoint
    render json: {
      success: true,
      message: "This is a mock response from the development Test API for Custom Channels.",
      received_method: request.method,
      received_headers: request.headers.to_h.select { |k, _| k.start_with?("HTTP_") || k == "CONTENT_TYPE" },
      received_params: params.except(:controller, :action).to_unsafe_h,
      signature_matched: request.headers["Deskbolic-Signature"].present?
    }
  end
end
