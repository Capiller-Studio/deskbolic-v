# frozen_string_literal: true

module Dashboard
  class PopupController < DashboardController
    def modal_popup
      @popup_view = params[:step]
      
      render "#{@popup_view}", layout: false
    end
  end
end