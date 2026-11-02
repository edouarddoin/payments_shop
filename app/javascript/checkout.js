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
    locale: 'en-US',
    countryCode: 'FR',
    showPayButton: true,
    clientKey: container.dataset.clientKey, // Public key used for client-side authentication: https://docs.adyen.com/development-resources/client-side-authentication
    onPaymentCompleted: (result, component) => {
        console.info(result, component);
    },
    onPaymentFailed: (result, component) => {
        console.info(result, component);
    },
    onError: (error, component) => {
        console.error(error.name, error.message, error.stack, component);
    },
    onSubmit(state, component, actions){
        console.info(state, component, actions);
    },
    beforeSubmit(data, component, actions){
        console.log(data, component, actions);
    }
  };

  const dropinConfiguration = {
      paymentMethodsConfiguration: {
          card: {
              hasHolderName: true,
              holderNameRequired: true, 
              openFirstPaymentMethod: true
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