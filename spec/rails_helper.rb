# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'shoulda/matchers'
require 'database_cleaner/active_record'
require 'factory_bot_rails'
require 'ffaker'
require 'timecop'
require 'pundit/matchers'

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

module SubdomainHelpers
  def set_subdomain(subdomain)
    host! "#{subdomain}.example.com"
  end

  def host_for_account(account)
    set_subdomain(account.identifier)
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
