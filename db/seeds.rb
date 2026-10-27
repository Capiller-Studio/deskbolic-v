# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if Rails.env.development?
  Seeds::CountriesSeeder.new.seed
  Seeds::StatesSeeder.new.seed
  Seeds::PlanSeeder.seed
  Seeds::AdminSeeder.seed
  Seeds::DevelopmentSeeder.seed
  Seeds::Development::AffiliateSeeder.seed
  api_domain = ENV.fetch("API_PORTAL_DOMAIN", "developers.deskbolic.localhost")
  help_domain = ENV.fetch("HELP_PORTAL_DOMAIN", "help.deskbolic.localhost")
  Seeds::ApiDocumentationSeeder.seed(domain: api_domain)
  Seeds::ProductDocumentationSeeder.seed(domain: help_domain, api_portal_domain: api_domain)
elsif Rails.env.production?
  Seeds::CountriesSeeder.new.seed
  Seeds::StatesSeeder.new.seed
  Seeds::PlanSeeder.seed
  Seeds::AdminSeeder.seed
  # api_domain = ENV.fetch("API_PORTAL_DOMAIN", "developers.deskbolic.com")
  # help_domain = ENV.fetch("HELP_PORTAL_DOMAIN", "help.deskbolic.com")
  # Seeds::ApiDocumentationSeeder.seed(domain: api_domain)
  # Seeds::ProductDocumentationSeeder.seed(domain: help_domain, api_portal_domain: api_domain)
end
