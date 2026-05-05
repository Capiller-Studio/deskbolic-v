# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.1"

# Rails base
gem "rails", ">= 8.0.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "jbuilder"

# Asset & View layers (Unique to Main App)
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"
gem "slim-rails"
gem "mjml-rails"
gem "actionpack-page_caching"
gem "invisible_captcha"

group :development, :test do
  gem 'dotenv-rails'
  gem 'pry'
  gem 'pry-rails'
  gem 'awesome_print'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'rubocop-rails-omakase', require: false
  gem 'slim_lint', '0.24.0', require: false
end

group :development do
  gem 'annotate'
  gem 'bullet'
  gem "web-console"
  gem "rack-mini-profiler"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem 'shoulda', '~> 4.0'
end

# ============================================================================
# Shared Backend (Core)
# ============================================================================
# gem 'core', git: "git@github.com:deskbolic/core.git"
gem 'core', path: "../core"

# All shared functional gems are now provided by 'core'.
