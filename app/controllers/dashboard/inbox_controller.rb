# frozen_string_literal: true

module Dashboard
  class InboxController < DashboardController
    def index
      @channels = Channel::FacebookPage.all
    end
  end
end
