# frozen_string_literal: true

module Dashboard
  class FacebookPageController < DashboardController
    def index
      access_token = params[:accessToken]
      
      client = Koala::Facebook::OAuth.new("1094575161783844", "6d329c722851dc658b4c5a0feed57c36")
      # client = Koala::Facebook::OAuth.new("2098895393814444", "123f45ee129e4069d1af082fbededa3b")
      response = client.exchange_access_token_info(access_token)

      client = Koala::Facebook::API.new(response['access_token'])
      client.get_connections('me', 'accounts')      
    end
    # def show; end
  end
end
