# frozen_string_literal: true

module Dashboard
  module CustomersHelper
    def customer_name(customer)
      full_name(customer).presence || customer.email.presence || customer.full_phone_number.presence || t("dashboard.customers.unknown", default: "Unknown customer")
    end

    def customer_searchable_text(customer)
      [
        customer_name(customer),
        customer.email,
        customer.full_phone_number,
        customer.username,
        customer.identifier,
        customer.external_id
      ].compact_blank.join(" ").downcase
    end

    def customer_channel_inboxes(customer)
      customer.customer_inboxes.filter_map(&:inbox).uniq(&:id).sort_by { |inbox| inbox.name.to_s.downcase }
    end

    def customer_channel_label(inbox)
      type = channel_overview_type_label(inbox.channel)
      inbox.name.present? ? "#{inbox.name} · #{type}" : type
    end

    def customer_channel_filter_values(customer)
      customer_channel_inboxes(customer).map(&:id).join(",")
    end

    def customer_contact_value(customer)
      customer.email.presence || customer.full_phone_number.presence || customer.username.presence || t("general.not_available", default: "Not available")
    end

    def customer_type_label(customer)
      t("dashboard.customers.types.#{customer.customer_type}", default: customer.customer_type.to_s.humanize)
    end

    def customer_gender_label(customer)
      return if customer.gender.blank?

      t("dashboard.customers.genders.#{customer.gender}", default: customer.gender.humanize)
    end

    def customer_identity_type_label(identity)
      t("dashboard.customers.identity_types.#{identity.identity_type}", default: identity.identity_type.humanize)
    end

    def customer_last_activity(customer)
      customer.last_activity_at || customer.updated_at
    end

    def customer_detail_items(customer)
      [
        [ t("dashboard.customers.fields.name", default: "Name"), customer_name(customer) ],
        [ t("dashboard.customers.fields.email", default: "Email"), customer.email ],
        [ t("dashboard.customers.fields.phone", default: "Phone"), customer.full_phone_number ],
        [ t("dashboard.customers.fields.username", default: "Username"), customer.username ],
        [ t("dashboard.customers.fields.locale", default: "Language"), customer.locale&.upcase ],
        [ t("dashboard.customers.fields.type", default: "Customer Type"), customer_type_label(customer) ],
        [ t("dashboard.customers.fields.gender", default: "Gender"), customer_gender_label(customer) ],
        [ t("dashboard.customers.fields.date_of_birth", default: "Date of Birth"), customer.dob && l(customer.dob, format: :long) ],
        [ t("dashboard.customers.fields.identifier", default: "Identifier"), customer.identifier ],
        [ t("dashboard.customers.fields.external_id", default: "External ID"), customer.external_id ],
        [ t("dashboard.customers.fields.created", default: "Created"), l(customer.created_at, format: :long) ],
        [ t("dashboard.customers.fields.last_activity", default: "Last Activity"), l(customer_last_activity(customer), format: :long) ]
      ]
    end

    def customer_identity_name(identity)
      identity.name.presence || identity.identity_source&.name.presence || customer_identity_type_label(identity)
    end

    def customer_identity_source(identity)
      identity.identity_source&.name.presence || customer_identity_type_label(identity)
    end
  end
end
