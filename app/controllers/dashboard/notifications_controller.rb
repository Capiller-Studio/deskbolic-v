# frozen_string_literal: true

module Dashboard
  class NotificationsController < DashboardController
    before_action :set_notification, only: [:mark_read]

    def index
      authorize Notification

      @pagy, @notifications = pagy(
        current_user.notifications.includes(:resource).recent,
        limit: 20
      )

      respond_to do |format|
        format.html { render layout: false }
        format.turbo_stream
      end
    end

    def mark_read
      authorize @notification
      
      @notification.update(read_at: Time.current)
      
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace(
            "notification_#{@notification.id}", 
            partial: "dashboard/notifications/notification", 
            locals: { notification: @notification }
          ) + turbo_stream.replace(
            "notification-badge", 
            partial: "dashboard/notifications/badge"
          )
        }
        format.html { redirect_back fallback_location: root_path }
      end
    end

    def mark_all_read
      authorize Notification
      
      current_user.notifications.unread.update_all(read_at: Time.current)
      
      respond_to do |format|
        format.turbo_stream { 
          @pagy, @notifications = pagy(current_user.notifications.includes(:resource).recent, limit: 20)
          
          render turbo_stream: turbo_stream.update(
            "notifications-list", 
            partial: "dashboard/notifications/list", 
            locals: { notifications: @notifications }
          ) + turbo_stream.replace(
            "notification-badge", 
            partial: "dashboard/notifications/badge"
          )
        }
        format.html { redirect_back fallback_location: root_path, notice: I18n.t("notifications.marked_all_read", default: "All notifications marked as read.") }
      end
    end

    def update_badge
      authorize Notification, :index?
      
      render turbo_stream: turbo_stream.replace(
        "notification-badge",
        partial: "dashboard/notifications/badge"
      )
    end

    private

    def set_notification
      @notification = current_user.notifications.find(params[:id])
    end
  end
end
