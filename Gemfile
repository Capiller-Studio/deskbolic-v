# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", ">= 8.0.1"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Shared backend
# For production
# gem 'core', git: "git@github.com:deskbolic/core.git"
# For development
gem 'core', path: "../core"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Template parsing
gem 'liquid'

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.2.5"

gem "anycable-rails"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variant
gem 'image_processing'

# Active Storage validations
gem 'active_storage_validations'

# For Active Storage S3 storage
gem "aws-sdk-s3", require: false

# Background jobs processing
gem 'sidekiq'

# Cron Jobs
gem 'whenever', require: false

# For Authentication
gem 'devise'
gem 'omniauth-facebook'
gem 'omniauth-rails_csrf_protection'

gem 'ancestry'

# Search
gem 'searchkick'

# JSON Optimization
gem 'oj'

# Persistent HTTP Connections
gem 'typhoeus'

# Authorization
gem 'pundit'

# Extensions to ruby string class
gem 'stringex'

# Money and currency conversion utilities
gem 'money'

# Pdf
gem 'prawn'
gem 'prawn-table'

# svg-inline
gem 'inline_svg'

# Group by date query support
gem 'groupdate'

# Models localization
gem 'mobility', '~> 1.3.0.rc1'

# Channels
gem 'facebook-messenger'
gem 'koala'

# For downloading files
gem 'down'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  # gem "debug", platforms: %i[ mri windows ]

  gem 'pry'
  gem 'pry-rails' # use pry for Rails console
  gem 'awesome_print'

  gem 'rubocop', '1.71.0', require: false
  gem 'rubocop-rails', '2.29.1', require: false
  gem 'rubocop-minitest', '0.36.0', require: false
  gem 'rubocop-thread_safety', '0.5.1', require: false
  gem 'rubocop-performance', '1.23.0', require: false
  gem 'rubocop-capybara', '2.21.0', require: false

  gem 'slim_lint', '0.24.0', require: false

  gem 'factory_bot_rails'
  gem 'ffaker'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem 'bullet'
  gem 'annotate'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem 'shoulda', '~> 4.0'
end

gem 'slim-rails'

# Email templating
gem 'mjml-rails'

# Pagination
gem 'pagy', '~> 6.2'

# Page Cache
gem "actionpack-page_caching"

# Countries and States data
gem 'carmen'

# Security
gem 'rack-attack'

# Spam protection
gem 'invisible_captcha'

# locating ip address
gem 'maxmind-geoip2'

gem 'httparty'

# Cryptography
gem 'openssl'

# bitwise features flag
gem 'flag_shih_tzu'
