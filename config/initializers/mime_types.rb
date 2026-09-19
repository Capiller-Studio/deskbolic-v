# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
Mime::Type.register "application/scim+json", :scim

ActionDispatch::Request.parameter_parsers[Mime::Type.lookup("application/scim+json").symbol] = ->(raw_post) {
  ActiveSupport::JSON.decode(raw_post)
}
