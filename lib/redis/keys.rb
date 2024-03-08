# frozen_string_literal: true

module Redis
  module Keys
    INBOX_AGENTS = "INBOX:%{account_id}:%{inbox_id}:AGENTS"
    PENDING_EMAIL = "PENDING_EMAIL:%{account_id}:%{id}"
    ONLINE_STATUS = "ONLINE_STATUS:%{account_id}"
    CUSTOMERS_ACTIVITY = "CUSTOMERS:%{account_id}:ACTIVITY"
    USERS_ACTIVITY = "USERS:%{account_id}:ACTIVITY"
    EMAIL_LOCK = "EMAIL_LOCK:%{account_id}:%{id}"
  end
end
