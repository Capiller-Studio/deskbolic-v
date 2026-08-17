# frozen_string_literal: true

puts "Cleaning up old test data..."
# Use with caution! Only for dev seeding.
# Account.destroy_all

puts "Creating Enterprise Account..."
account = Account.find_or_create_by!(identifier: "enterprise-1") do |a|
  a.name = "Enterprise Solutions Inc."
end

puts "Generating Default Roles..."
# This is usually handled by the after_create hook in Account,
# but we call it explicitly here just in case.
Access::RoleGenerator.call(account)

puts "Creating Users..."
owner_user = User.find_or_create_by!(email: "owner@enterprise.com") do |u|
  u.password = "Password123!"
  u.first_name = "Jane"
  u.last_name = "Owner"
  u.confirmed_at = Time.zone.now
end

admin_user = User.find_or_create_by!(email: "admin@enterprise.com") do |u|
  u.password = "Password123!"
  u.first_name = "John"
  u.last_name = "Admin"
  u.confirmed_at = Time.zone.now
end

agent_user = User.find_or_create_by!(email: "agent@enterprise.com") do |u|
  u.password = "Password123!"
  u.first_name = "Alice"
  u.last_name = "Agent"
  u.confirmed_at = Time.zone.now
end

limited_agent = User.find_or_create_by!(email: "limited@enterprise.com") do |u|
  u.password = "Password123!"
  u.first_name = "Bob"
  u.last_name = "Limited"
  u.confirmed_at = Time.zone.now
end

puts "Mapping Users to Account..."
# Owner
AccountUser.find_or_create_by!(account: account, user: owner_user) do |au|
  au.role = :owner
end

# Admin
admin_role = account.roles.find_by(name: "Administrator")
AccountUser.find_or_create_by!(account: account, user: admin_user) do |au|
  au.role = :admin
  au.roles << admin_role
end

# Standard Agent
agent_role = account.roles.find_by(name: "Agent")
AccountUser.find_or_create_by!(account: account, user: agent_user) do |au|
  au.role = :agent
  au.roles << agent_role
end

puts "Creating Custom Conditional Roles..."
# Custom role for Bob who can only see certain inboxes
inbox1 = account.inboxes.create!(name: "Sales Support", channel: Channel::WebWidget.create!(account: account))
inbox2 = account.inboxes.create!(name: "Technical Support", channel: Channel::WebWidget.create!(account: account))

restricted_role = account.roles.create!(
  name: "Restricted Agent",
  permissions: {
    "conversations" => {
      "read" => { "conditions" => { "inbox_ids" => [ inbox1.id.to_s ] } }, # Can only read inbox 1
      "write" => { "conditions" => { "inbox_ids" => [ inbox1.id.to_s ] } } # Can only write to inbox 1
    }
  }
)

AccountUser.find_or_create_by!(account: account, user: limited_agent) do |au|
  au.role = :agent
  au.roles << restricted_role
end

puts "Creating Conversations..."
customer = account.customers.create!(email: "customer@example.com", name: "Guest User")
conv1 = account.conversations.create!(customer: customer, inbox: inbox1, status: :active)
conv2 = account.conversations.create!(customer: customer, inbox: inbox2, status: :active)

conv1.messages.create!(content: "Help with sales!", account: account, sender: customer, inbox: inbox1)
conv2.messages.create!(content: "My server is down!", account: account, sender: customer, inbox: inbox2)

puts "Seeding Contact Form..."
Seeds::ContactFormSeeder.seed(account)

puts "Seeding Completed Successfully! 🚀"
