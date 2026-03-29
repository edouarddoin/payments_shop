class StripeCheckoutSession
  def call(checkout_session_id)
    order = Order.find_by(checkout_session_id)
    order.update(status_id: 9)
  end

  class ValidatingEventLogger
    def initialize(logger)
      @logger = logger
    end

    def call(event)
      @logger.info "BILLING:#{event.type}:#{event.id}"
    end
  end
end
