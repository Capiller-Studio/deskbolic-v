# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Customers
  class CustomerSearcher < ApplicationService
    attr_accessor :params, :customers, :per_page,
                  :paginate, :skip_search, :mail, :account

    DEFAULT_PER_PAGE = 28

    def initialize(params: {}, account: nil, mail: nil, paginate: false, includes: [], _elastic_search: true)
      self.emails     = emails
      self.mail       = mail
      self.per_page             = params[:per_page] || DEFAULT_PER_PAGE
      self.paginate             = paginate
      self.params               = params
      self.filtered = false
      self.account = account
      self.skip_search = skip_search
      self.customers = account.customers
      self.conditions = {
        where: {}, order: { _score: :desc },
        includes:, match: :word_middle
      }
    end

    def call
      parse_params_from_mail
      find_email_channels

      filter_by_account
      filter_by_id
      apply_ordering
      apply_pagination

      self.conditions = conditions.compact_blank!

      return Customer.search(params[:search], **conditions) if params[:search].present?

      return customers if !filtered || !elastic_search

      Customer.search(**conditions)
    end

    private

    def filter_by_id
      return if params[:id].blank?

      self.filtered = true
      self.customers = customers.where(id: params[:id])

      conditions[:where].merge!(id: params[:id])
    end

    def filter_by_account
      conditions[:where].merge!(account_id: account.id)
    end

    def apply_pagination
      return customers unless paginate

      self.customers = customers.page(params[:page]).per(per_page)
      conditions.merge!(page: params[:page], per_page:)
    end

    def apply_ordering
      return if params[:order_by].blank?

      field, direction = params[:order_by].split(":")

      self.customers = customers.order(field.to_sym => direction)
      conditions[:order] = { field.to_sym => direction }
    end

    def parse_params_from_mail
      return if mail.blank?

      self.emails += mail.to.to_a + mail.bcc.to_a + mail.cc.to_a + [mail["X-Original-To"]&.value]
    end
  end
end
