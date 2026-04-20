# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_customer

    def connect
      self.current_user = find_user
      self.current_customer = find_customer

      reject_unauthorized_connection unless current_user || current_customer
    end

    private

    def find_user
      token = request.params[:user_token]
      return unless token.present?

      User.find_by(connection_token: token)
    end

    def find_customer
      token = request.params[:customer_token]
      return unless token.present?

      customer_inbox = CustomerInbox.find_by(connection_token: token)
      customer_inbox&.customer
    end
  end
end
