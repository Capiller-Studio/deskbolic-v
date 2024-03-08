# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Customers
  class CustomerCreator < ApplicationService
    attr_accessor :params, :customer, :account, :inbox, :customer_inbox,
                  :external_id, :full_phone_number, :email

    def initialize(account:, inbox:, external_id: nil, email: nil,
                   full_phone_number: nil, params: {})
      self.account             = account
      self.inbox               = inbox
      self.external_id         = external_id
      self.email               = email
      self.full_phone_number   = full_phone_number
      self.full_phone_number ||= "#{params[:phone_code]}#{params[:phone_number]}"
      self.params              = params
    end

    def call
      self.customer_inbox = inbox.customer_inboxes.find_by(external_id:) if external_id.present?
      return customer_inbox.customer if customer_inbox

      find_or_create_customer

      ActiveRecord::Base.transaction do
        find_or_create_customer
        # TODO: Logic to attach some profile-picture/avatar. Maybe something random, if we can't fetch it
      end

      customer_inbox&.customer
    end

    private

    def find_or_create_customer
      find_customer || create_customer
      create_customer_inbox
    end

    def find_customer
      find_customer_by_external_id || find_customer_by_email || find_customer_by_phone_number
    end

    def find_customer_by_external_id
      return if external_id.blank?

      self.customer = account.customers.find_by(external_id:)
    end

    def find_customer_by_email
      return if email.blank?

      self.customer = account.customers.find_by(email: email.downcase)
    end

    def find_customer_by_phone_number
      return if full_phone_number.blank?

      self.customer = account.customers.find_by(full_phone_number:)
    end

    def create_customer
      # TODO: Fix address
      self.customer = account.customers.create!(
        name: params[:name] || "Fancy Name Logic",
        full_phone_number:,
        # phone_code: params[:phone_code],
        # phone_number: params[:phone_number],
        first_name: params[:first_name],
        middle_name: params[:middle_name],
        last_name: params[:last_name],
        email:,
        external_id:,
        address: Address.create!
      )
    end

    def create_customer_inbox
      CustomerInboxCreator.call(
        customer: @customer,
        inbox:,
        external_id:,
        account:
      )
    end
  end
end
