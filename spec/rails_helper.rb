# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'
require 'shoulda/matchers'
require 'database_cleaner/active_record'
require 'factory_bot_rails'
require 'ffaker'
require 'timecop'
require 'pundit/matchers'
require 'sidekiq/testing'
Sidekiq::Testing.inline!

FactoryBot.definition_file_paths = [
  Core::Engine.root.join('spec/factories'),
  Rails.root.join('spec/factories')
]
FactoryBot.find_definitions if FactoryBot.factories.count == 0

ActiveRecord::Encryption.configure(
  primary_key: 'test_primary_key_for_rspec_testing',
  deterministic_key: 'test_deterministic_key_for_rspec',
  key_derivation_salt: 'test_key_derivation_salt_rspec'
)

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--window-size=1400,1000')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--window-size=1400,1000')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = ENV['HEADLESS'] == 'false' ? :selenium_chrome : :selenium_chrome_headless
Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Silent: true }
Capybara.always_include_port = true
Capybara.default_host = 'http://lvh.me'
Capybara.app_host = 'http://lvh.me'

module SubdomainHelpers
  def set_subdomain(subdomain)
    host! "#{subdomain}.example.com"
  end

  def host_for_account(account)
    set_subdomain(account.identifier)
  end
end

module FeatureSubdomainHelpers
  def current_server_port
    server = Capybara.current_session.server
    return server.port if server

    if Capybara.current_driver != :rack_test
      Capybara.current_session.server
      Capybara.current_session.server&.port
    end
  end

  def set_subdomain(subdomain)
    port = current_server_port
    port_str = port ? ":#{port}" : ""
    Capybara.app_host = "http://#{subdomain}.lvh.me#{port_str}"
    Capybara.default_host = "http://#{subdomain}.lvh.me#{port_str}"
  end

  def host_for_account(account)
    set_subdomain(account.identifier)
  end

  def reset_subdomain
    port = current_server_port
    port_str = port ? ":#{port}" : ""
    Capybara.app_host = "http://lvh.me#{port_str}"
    Capybara.default_host = "http://lvh.me#{port_str}"
  end
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = false # Set to false to use DatabaseCleaner

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include SubdomainHelpers, type: :request
  config.include Warden::Test::Helpers, type: :feature
  config.include FeatureSubdomainHelpers, type: :feature

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Searchkick.disable_callbacks if defined?(Searchkick)
    InvisibleCaptcha.timestamp_threshold = 0 if defined?(InvisibleCaptcha)
    InvisibleCaptcha.spinner_enabled = false if defined?(InvisibleCaptcha)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation
    reset_subdomain
  end

  config.after(:each, type: :feature) do
    Warden.test_reset!
    reset_subdomain
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
