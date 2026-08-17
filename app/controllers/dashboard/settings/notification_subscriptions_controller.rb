# frozen_string_literal: true

module Dashboard
  module Settings
    class NotificationSubscriptionsController < DashboardController
      def create
        @subscription = current_user.notification_subscriptions.find_or_initialize_by(
          subscription_type: :push,
          data: { "endpoint" => subscription_params[:endpoint] }
        )

        authorize(@subscription)

        @subscription.data = {
          endpoint: subscription_params[:endpoint],
          p256dh: subscription_params[:p256dh],
          auth: subscription_params[:auth]
        }

        if @subscription.save
          render(json: { success: true }, status: :ok)
        else
          render(json: { error: @subscription.errors.full_messages }, status: :unprocessable_entity)
        end
      end

      def destroy
        @subscription = current_user.notification_subscriptions.find_by("data->>'endpoint' = ?", params[:endpoint])
        authorize(@subscription) if @subscription

        if @subscription&.destroy
          render(json: { success: true }, status: :ok)
        else
          render(json: { success: false }, status: :not_found)
        end
      end

      private

      def subscription_params
        params.expect(subscription: [ :endpoint, :p256dh, :auth ])
      end
    end
  end
end
