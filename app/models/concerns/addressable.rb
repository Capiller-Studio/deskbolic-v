# frozen_string_literal: true

module Addressable
  extend ActiveSupport::Concern

  included do
    belongs_to :address

    %i[address1 address2 phone_code alternative_phone_code
       phone_number alternative_phone_number city state_id country_id
       organization_name state_name zipcode national_id country state].each do |method_name|
      delegate method_name, :"#{method_name}=", to: :find_or_build_address
    end

    accepts_nested_attributes_for :address

    private

    def find_or_build_address
      address || build_address
    end
  end

  class_methods do
    def sample_method; end
  end
end
