# frozen_string_literal: true

module Dashboard
  class HelpDeskController < DashboardController
    def index
      @em_channels = Channel::Email.first
      @fb_channels = Channel::FacebookPage.first
    end
  end
end
