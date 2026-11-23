class AdyenWebhooksController < ApplicationController
    skip_before_action :verify_authentication_token
    skip_before_action :authentication_user!, raise: false

    def create
        items = params.to_unsafe_h.fetch("notificationItems", [])

        items.each do |wrapper|
            item = wrapper["NotificationRequestItem"]
            next unless valid_hmac?(item)
            handle(item)
        end

        render plain: "[accepted]", status: :ok #adyen expects accepted and 200
    end

    private

    def valid_hmac?(item)
        Adyen::Utils::HmacValidator.new.valid_webhook_hmac?(item, ENV.fetch("ADYEN_HMAC_KEY"))
    end

    def handle(item)
        return unless item["eventCode"] == "AUTHORISATION" && item["success"] == "true"

        order_id = item["merchantReference"].to_s.delete_prefix("order-")
        order = Order.find_by(id: order_id)
        order.validate if order && order.status_id != 2   # safe if Adyen resends
    end
  end
