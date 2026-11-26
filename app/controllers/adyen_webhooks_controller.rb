class AdyenWebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!
    http_basic_authenticate_with name: ENV.fetch("ADYEN_WEBHOOK_USER"),
        password: ENV.fetch("ADYEN_WEBHOOK_PASSWORD")
    before_action :verify_hmac

    def create
        item = params.to_unsafe_h.fetch("notificationItems", [])
        render plain: "[accepted]", status: :ok #adyen expects accepted and 200
    end

    private

    def verify_hmac
        payload = JSON.parse(request.raw_post)
        @items  = payload.fetch("notificationItems", []).map { |w| w["NotificationRequestItem"] }

        results = @items.map { |i| valid_hmac?(i) }
        Rails.logger.info "[Adyen webhook] items=#{@items.size} " \
                            "signature_present=#{@items.map { |i| i.dig('additionalData', 'hmacSignature').present? }.inspect} " \
                            "hmac_valid=#{results.inspect} key_length=#{ENV['ADYEN_HMAC_KEY'].to_s.length}"

        head :unauthorized unless results.any? && results.all?
    end

    def valid_hmac?(item)
        Adyen::Utils::HmacValidator.new.valid_webhook_hmac?(item, ENV.fetch("ADYEN_HMAC_KEY"))
    end

    def handle(item)
        return unless item["eventCode"] == "AUTHORISATION" && item["success"] == "true"

        order_id = item["merchantReference"].to_s.delete_prefix("order-")
        order = Order.find_by(id: order_id)
        order.validate if order && order.status_name != "validated"   # safe if Adyen resends
    end
  end
