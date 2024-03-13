# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # identified_by :current_subscriber

    # rescue_from StandardError, with: :handle_exception

    # def connect
    #   self.current_subscriber = find_subscriber
    # end

    # private

    # def find_subscriber
    # end

    # def handle_exception(e)
    # end
  end
end
