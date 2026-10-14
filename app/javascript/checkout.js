const globalConfiguration = {
  session: {
    id: $session_id, // Unique identifier for the payment session.
    sessionData: $session_data // The payment session data.
  },
  environment: 'test', // Change to 'live' for the live environment.
  amount: {
    value: $amount_value,
    currency: $currency
  },
  locale: 'nl-NL',
  countryCode: 'NL',
  clientKey: $client_key, // Public key used for client-side authentication: https://docs.adyen.com/development-resources/client-side-authentication
  onPaymentCompleted: (result, component) => {
    console.info(result, component);
  },
  onPaymentFailed: (result, component) => {
    console.info(result, component);
  },
  onError: (error, component) => {
    console.error(error.name, error.message, error.stack, component);
  }
};

const dropinConfiguration = {
   // Required if you import individual payment methods.
   paymentMethodComponents: [Card, PayPal, GooglePay, ApplePay, Ideal],
   // Optional configuration.
   onReady: () => {},
   instantPaymentTypes: ['applepay', 'googlepay']
};