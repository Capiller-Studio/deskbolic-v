# frozen_string_literal: true

module Dashboard
  module AutomationsHelper
    EVENT_TRIGGER_EVENTS = %w[
      conversation.created conversation.updated conversation.status_changed
      conversation.assigned conversation.resolved
      message.created message.incoming message.outgoing
      customer.created customer.updated
      sla.breached
    ].freeze

    TIME_TRIGGER_EVENTS = %w[
      hours_since_created hours_since_updated
      hours_since_resolved hours_since_last_activity
    ].freeze

    def event_options_for_type(type)
      events = type.to_s == "time_trigger" ? TIME_TRIGGER_EVENTS : EVENT_TRIGGER_EVENTS
      events.map { |e| [ t("dashboard.automations.events.#{e.tr('.', '_')}", default: e.titleize), e ] }
    end

    def condition_attribute_options
      Automations::AutomationValidator::VALID_CONDITION_ATTRIBUTES.map do |attr|
        [ t("dashboard.automations.attributes.#{attr.tr('.', '_')}", default: attr.titleize), attr ]
      end
    end

    def condition_operator_options
      Automations::AutomationValidator::VALID_CONDITION_OPERATORS.map do |op|
        [ t("dashboard.automations.operators.#{op}", default: op.titleize), op ]
      end
    end

    def action_type_options
      Automations::ActionExecutor::ACTION_HANDLERS.keys.map do |action|
        [ t("dashboard.automations.actions.#{action}", default: action.titleize), action ]
      end
    end

    def agent_options_for_select
      return [] unless current_account

      current_account.users.pluck(:name, :id)
    end

    def team_options_for_select
      return [] unless current_account

      current_account.teams.pluck(:name, :id)
    end

    def label_options_for_select
      return [] unless current_account

      current_account.labels.pluck(:title, :id)
    end
  end
end
