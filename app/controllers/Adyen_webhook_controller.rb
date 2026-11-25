class AdyenWebhooksController < ApplicationController
    skip_before_action :verify_authentication_token
    skip_before_action :authentication_user!, raise: false
    http_basic_authenticate_with name: ENV.fetch("ADYEN_WEBHOOK_USER"),
                               password: ENV.fetch("ADYEN_WEBHOOK_PASSWORD")
    before_action :verify_hmac

    def create
        items = params.to_unsafe_h.fetch("notificationItems", [])
        render plain: "[accepted]", status: :ok #adyen expects accepted and 200
    end

    private

    def valid_hmac?(item)
        @items = params.to_unsafe_h.fetch("notificationItems", [])
                    .map { |w| w["NotificationRequestItem"] }

             = @items.present? && @items.all? { |item| valid_hmac?(item) }
        head :unauthorized unless valid
    end

    def handle(item)
        return unless item["eventCode"] == "AUTHORISATION" && item["success"] == "true"

        order_id = item["merchantReference"].to_s.delete_prefix("order-")
        order = Order.find_by(id: order_id)
        order.validate if order && order.status_name != "validated"   # safe if Adyen resends
    end
  end
