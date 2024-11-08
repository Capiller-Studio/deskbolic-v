# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class EventBroadcastWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: "default"

  def perform(data, event, connection_tokens = nil, retries = 0)
    # account = Account.find_by(id: account_id)
    # return if account.blank? || event.blank?

    # TODO: WIP, add webhook broadcasting and email notifications
    
    result = ActionCables::EventBroadcaster.call(
      data: data, event: event,
      connection_tokens: connection_tokens
    )
  
    return if result || retries >= 2

    self.class.perform_in(10.minutes, data, event, connection_tokens, retries + 1)
  end
end