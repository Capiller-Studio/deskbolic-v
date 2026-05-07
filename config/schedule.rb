# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, "log/cron.log"
set :environment, "production"

# --- SLA Management ---
# Periodically check for breached SLAs and trigger notifications
every 5.minutes do
  runner "SlaCheckWorker.perform_async"
end

# --- Maintenance ---
# Reset usage limits for accounts (if applicable)
every 1.day, at: "12:00 am" do
  runner "UsageResetWorker.perform_async"
end

# Update exchange rates for billing (if using multi-currency)
every 1.day, at: "1:00 am" do
  runner "ExchangeRatesUpdaterWorker.perform_async"
end

# Clear expired trials
every 1.day, at: "2:00 am" do
  runner "TrialExpirationWorker.perform_async"
end
