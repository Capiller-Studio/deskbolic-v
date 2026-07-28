# frozen_string_literal: true

module Webhooks
  # TODO: Implement if/when Channel::WebWidget requires external webhook ingestion.
  # Channel::WebWidget is Deskbolic's own first-party live chat widget — no external
  # provider sends webhooks to this endpoint currently. Routes are kept for future use.
  class WidgetController < Webhooks::BaseController
  end
end
