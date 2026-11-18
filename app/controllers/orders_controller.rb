require 'adyen-ruby-api-library'

class OrdersController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    order = Order.create!(product: product, product_sku: product.sku, amount_cents: product.price_cents, status_id: 1, user_id: current_user.id)
    if order.persisted?
      redirect_to order_path(order.id), notice: "Your order number #{order.id} created successfully"
    else
      redirect_to product_path(product.id), alert: "Failed to create order."
    end

  end
  
  def pay
    @currency = "EUR"
    @order = current_user.orders.find_by(id: params[:id])
    @order_price = @order.amount_cents.to_i if @order.present?
    @adyen_session = create_adyen_session(@order)
    @adyen_session_id = @sessionId
    @adyen_session_data = @sessionData
    $client_key = ENV.fetch('ADYEN_CLIENT_KEY')
  end

  def show
    @order = current_user.orders.find_by(id: params[:id])
  end

  def apply_discount
    @order = current_user.orders.find_by(id: params[:id])
    discount_code = params[:discount_code]
    discountValue = Discount.find_by(code: discount_code)&.amount_cents
    Rails.logger.debug { "Discount amount applied is: #{discountValue} | to order: #{@order.id}" }
    if discount_code.present? && discountValue.present? 
      @order.update(amount_cents: @order.amount_cents - discountValue)
      flash.now[:"notice"] = "Discount code applied successfully."
      #once the discount is applied, the session needs to be updated with the new order price. 
      updateSession
    else
      Rails.logger.debug { "Invalid discount code: #{discount_code} or discount value not found." }
      flash.now[:"alert"] = "Invalid discount code."
    end
    Rails.logger.debug { "New order price is: #{@order.amount_cents}"}
    # if necessary create a new value call "newOrderPrice" to store the new price after discount.
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
        "amount" => { currency: @currency, value: @order_price },
        "returnUrl" => order_url(@order.id),
        "reference" => "order-#{Time.now.to_i}",
        "countryCode" => "NL",
        "channel" => "Web",
        "expiresAt" => (Time.now + 3600).iso8601,
        "shopperLocale" => "en-US",
        "shopperEmail" => "edouard.doin@adyen.com",
        "shopperReference" => "user_id_#{current_user.id}",
        "recurringProcessingModel" => "CardOnFile",
        "shopperInteraction" => "Ecommerce",
        "storePaymentMethodMode" => "askForConsent",
        "payable" => false #needs to be switch to true once the order amount has been updated (discount, qty, ...).
    }
    result = adyen.checkout.payments_api.sessions(request_body, headers: { 'Idempotency-Key' => SecureRandom.uuid })
    # parsed_json = JSON.parse(json_string)
    sessionResponse = JSON.parse(result.response.to_json)
    # session_data = parsed_json["sessionData"]
    @sessionData = sessionResponse.dig("sessionData")
    @sessionId = sessionResponse.dig("id")



      # data = JSON.load_file('user_data.json')
      # puts "User: #{data['name']} (#{data['username']})"

    if Rails.env.development?
      Rails.logger.debug { "Adyen sessions request body: #{request_body.to_json}" }
      Rails.logger.debug { "----" }
      Rails.logger.debug { "Adyen sessions response: #{result.to_json}" }
      Rails.logger.info("Adyen sessions URL: #{adyen.service_url('Checkout', 'sessions', adyen.checkout.version)}")
      Rails.logger.info("Adyen session data: #{@sessionData}")
      Rails.logger.info("Adyen session Id: #{@sessionId}")

    else
      Rails.logger.debug { "This is not a development environment" }
    end

    rescue StandardError => e
    Rails.logger.error("Adyen session request failed: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    if e.respond_to?(:response)
    Rails.logger.error("Response details: #{e.response.inspect}")
    end
    raise
  end

  def updateSession
    adyen = Adyen::Client.new
    adyen.api_key = ENV.fetch('ADYEN_API_KEY')
    adyen.env = :test
    Rails.logger.info("IS ADYEN_ENVIRONMENT present: #{adyen.env.present?}")
    Rails.logger.info("IS ADYEN_API_KEY present: #{adyen.api_key.present?}")
    # Create a new session with the updated amount and currency
    request_body = {
      "sessionData" => @sessionData,
      "amount" => { currency: @currency, value: @order_price },
      "payable" => true # Set to true since the order amount has been updated
    }
    updateSession_result = adyen.checkout.payments_api.update_session(request_body, @sessionId, headers: { 'Idempotency-Key' => SecureRandom.uuid })
    Rails.logger.debug { "Adyen update session request body: #{request_body.to_json}" }
    Rails.logger.debug { "Adyen update session response: #{updateSession_result.to_json}" }
    Rails.logger.info("Adyen update session URL: #{adyen.service_url('UpdateSession', 'sessions', adyen.checkout.version)}")
  end

  def validate
    @order.update(status_id: 2)
  end

end