# frozen_string_literal: true

class BounceMailbox < ApplicationMailbox
  def process
    bounced!
  end
end
