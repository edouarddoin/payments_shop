require 'adyen-ruby-api-library'

class OrdersController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    order = Order.create!(product: product, product_sku: product.sku, amount_cents: product.price_cents, status_id: 1, user_id: current_user.id)
    if order.persisted?
      redirect_to order_path(order.id), notice: "Order.#{order.id} created successfully"
    else
      redirect_to product_path(product.id), alert: "Failed to create order."
    end
    adyen_session = create_adyen_session(order)
    
    # create the url and redirect the user to the order page. 

  # order_price = order.amount_cents.to_i

  end

  private

  def create_adyen_session(order)
    adyen = Adyen::Client.new
    adyen.api_key = ENV.fetch('ADYEN_API_KEY')
    adyen.env = ENV.fetch('ADYEN_ENVIRONMENT', 'test').to_sym
    idempotency_key = SecureRandom.uuid
    #Adyen create session documentation : https://docs.adyen.com/online-payments/web-drop-in/create-session
    request_body ={
        merchantAccount: ENV['ADYEN_MERCHANT_ACCOUNT'],  
        amount: { currency: "EUR", value: order.amount_cents.to_i },
        returnUrl: order_url(order),
        reference: "order-#{Time.now.to_i}",
        countryCode: "NL",
        channel: "Web",
        expiresAt: (Time.now + 3600).iso8601,
        shopperLocale: "en-US",
        shopperEmail: current_user.email,
        shopperReference: current_user.id,
      }
    checkout = Adyen::Checkout.new(adyen, 68)
    checkout.payments_api.sessions(
      request_body,
      headers: { 'Idempotency-Key' => SecureRandom.uuid }
    )
  rescue StandardError => e
    Rails.logger.error("Adyen session request failed: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
    # result = adyen.checkout.payments_api.sessions(request_body, headers: { 'Idempotency-Key' => idempotency_key })
  end

  def show
    @order = current_user.orders.find_by(id: params[:id])
  end

  def validate
    @order.update(status_id: 2)
  end
end
