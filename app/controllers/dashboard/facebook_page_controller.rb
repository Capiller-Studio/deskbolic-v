# frozen_string_literal: true

module Dashboard
  class FacebookPageController < DashboardController
    def index
      access_token = params[:accessToken]

      @client = Koala::Facebook::API.new(access_token)
      @pages = @client.get_connections("me", "accounts")

      render(turbo_stream: turbo_stream.append("facebook-page-frame", partial: "dashboard/popup/facebook_pages_modal",
locals: { pages: @pages })) if @pages
    end
    # def show; end
  end
end
