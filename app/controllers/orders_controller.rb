class OrdersController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    order = Order.create!(product: product, product_sku: product.sku, amount_cents: product.price_cents, status_id: 8, user: current_user)

    # Choisissez votre fournisseur de paiement
    stripe_session = create_stripe_session(order, product)
    # OU
    adyen_session = create_adyen_session(order)

  order.update(checkout_session_id: adyen_session.id)
  redirect_to new_order_payment_path(order)

  # order_price = order.amount_cents.to_i

  end

  private

  def create_stripe_session(order, product)
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    # link to documentation : https://stripe.com/docs/api/checkout/sessions/create
    Stripe::Checkout::Session.create({
      success_url: order_url(order),
      cancel_url: order_url(order),
      line_items:[
        {
          quantity: 1,
          price_data: {
            product_data: {
              name: product.name, description: product.description
            },
            unit_amount: product.price_cents.to_i,
            currency: 'eur',
          }
        }
      ],
      mode: 'payment',
    }
    )
  end

  def create_adyen_session(order)
    #Adyen create session documentation : https://docs.adyen.com/online-payments/web-drop-in/create-session
    AdyenPaymentService.({
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
        applicationInfo: {
          adyenLibrary: "Ruby Adyen API Library",
          adyenLibraryVersion: "1.0.0",
        }
      })
  end

  def show
    @order = current_user.orders.find(params[:id])
  end

  def validate
    @order.update(status_id: 9)
  end
end
