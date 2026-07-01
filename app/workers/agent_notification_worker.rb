# frozen_string_literal: true

class AgentNotificationWorker < BaseMutexWorker
  def perform(event_name, resource_class, resource_id, target_user_ids)
    resource = resource_class.constantize.find_by(id: resource_id)
    return unless resource

    account = resource.account

    Current.set(account: account) do
      account.with_shard do
        users = User.where(id: target_user_ids)
        
        users.each do |user|
          setting = NotificationSetting.find_or_create_by!(user: user, account: account)
          next unless setting.email_enabled_for?(event_name)

          # Smart Cancel: For messages, skip if the conversation has already been read in the UI
          if event_name == "message_created"
            unread_count = RedisUtilities::Helpers.hash_get(
              RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: account.id, member_id: user.id },
              resource.conversation_id
            ).to_i
            
            # Skip sending email if the unread count for this conversation is zero
            next if unread_count <= 0
          end

          AgentNotificationMailer.public_send(event_name, user, resource).deliver_later
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error("AgentNotificationWorker error: #{e.message}")
  end
end
