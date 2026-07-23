# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if Rails.env.development?
  Seeds::CountriesSeeder.new.seed
  Seeds::StatesSeeder.new.seed
  Seeds::PlanSeeder.seed
  Seeds::DevelopmentSeeder.seed
  Seeds::ApiDocumentationSeeder.seed(domain: "developers.deskbolic.localhost")
elsif Rails.env.production?
  Seeds::CountriesSeeder.new.seed
  Seeds::StatesSeeder.new.seed
  Seeds::PlanSeeder.seed
  # Seeds::ApiDocumentationSeeder.seed(domain: "developers.deskbolic.com")
end
