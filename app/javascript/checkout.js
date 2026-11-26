import { AdyenCheckout, Dropin } from '@adyen/adyen-web/auto';
import '@adyen/adyen-web/styles/adyen.css';

export async function initCheckout() {
  const container = document.querySelector("#dropin-container");
  if (!container) return;
  const Configuration = {
    session: {
      id: container.dataset.sessionId,      
      sessionData: container.dataset.sessionData
    },
    environment: 'test',
    amount: {
        value: Number(container.dataset.amount), // The amount value is in minor units. For example, for EUR 10.00, this value should be 1000.
        currency: 'EUR'
    },
    openFirstPaymentMethod: false,
    locale: 'en-US',
    countryCode: 'NL',
    showPayButton: true,
    clientKey: container.dataset.clientKey, // Public key used for client-side authentication: https://docs.adyen.com/development-resources/client-side-authentication
    onPaymentCompleted: (result, component) => {
      const orderId = container.dataset.orderId;
      window.location.href =`/orders/${orderId}/payment_result?sessionResult=${encodeURIComponent(result.sessionResult)}`;
      console.info("Payment completed:", result, component);
    },
    onPaymentFailed: (result, component) => {
        console.info("Payment failed:", result, component);
    },
    onError: (error, component) => {
        console.error("OnError is called:",error.name, error.message, error.stack, component);
    },
    beforeSubmit(data, component, actions, state){
        console.log('Before submit is called', state);
        console.info(data, component, actions);
        console.info("[Adyen] beforeSubmit entered");
        // Continue the Sessions flow.
        actions.resolve(data);
        console.info("[Adyen] beforeSubmit released");
    }
  };

  const dropinConfiguration = {
      paymentMethodsConfiguration: {
          card: {
              hasHolderName: true,
              holderNameRequired: true, 
              openFirstPaymentMethod: true,
              openFirstStoredPaymentMethod : true
          },
        onReady: () => {},
      }
  };
        
  console.log('Mounting Adyen Drop-in with shopper country and locale:', {
    countryCode: Configuration.countryCode,
    locale: Configuration.locale
  });

  const checkout = await AdyenCheckout(Configuration);
  new Dropin(checkout, dropinConfiguration).mount('#dropin-container');
}