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

  # order_price = order.amount_cents.to_i
  end

  def pay
    order = current_user.orders.find_by(id: params[:order_id])
    adyen_session = create_adyen_session(order)
  end

  def show
    @order = current_user.orders.find_by(id: params[:id])
  end
end

  private

  def create_adyen_session(order)
    adyen = Adyen::Client.new
    adyen.api_key = ENV.fetch('ADYEN_API_KEY')
    adyen.env = :test
    Rails.logger.info("IS ADYEN_ENVIRONMENT present: #{adyen.env.present?}")
    Rails.logger.info("IS ADYEN_API_KEY present: #{adyen.api_key.present?}")

    #Adyen create session documentation : https://docs.adyen.com/online-payments/web-drop-in/create-session
    request_body = {
        "merchantAccount" => ENV['ADYEN_MERCHANT_ACCOUNT'],  
        "amount" => { currency: "EUR", value: order.amount_cents.to_i },
        "returnUrl" => order_url(order),
        "reference" => "order-#{Time.now.to_i}",
        "countryCode" => "NL",
        "channel" => "Web",
        "expiresAt" => (Time.now + 3600).iso8601,
        "shopperLocale" => "en-US",
        "shopperEmail" => current_user.email,
        "shopperReference" => current_user.id
      }
    result = adyen.checkout.payments_api.sessions(request_body, headers: { 'Idempotency-Key' => SecureRandom.uuid })

    rescue StandardError => e
    Rails.logger.error("Adyen session request failed: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    if e.respond_to?(:response)
    Rails.logger.error("Response details: #{e.response.inspect}")
    end
    if Rails.env.development?
      logged_body = request_body.deep_dup

      %w[merchantAccount shopperEmail shopperReference reference returnUrl].each do |key|
        logged_body[key] = "[REDACTED]" if logged_body.key?(key)
      end
      Rails.logger.debug { "Adyen sessions request body: #{logged_body.to_json}" }

      logged_response = e.respond_to?(:response) ? e.response.deep_dup : nil
      if logged_response
        %w[pspReference resultCode].each do |key|
          logged_response[key] = "[REDACTED]" if logged_response.key?(key)
        end
        Rails.logger.debug { "Adyen sessions response: #{logged_response.to_json}" }
      end
    end
    raise
  end

  def validate
    @order.update(status_id: 2)
  end
