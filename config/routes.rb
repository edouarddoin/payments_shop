Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

# Webhook notification route for Adyen payment status updates
  post "/webhooks/adyen", to: "adyen_webhooks#create"

  # Defines the root path route ("/")
  root 'products#index'

  resources :products, only: [:index, :show, :new]

  resources :orders, only: [:show, :create, :validate, :update] do
    member do
      post :pay
      get :pay
      post :apply_discount
    end
  end
  
  resources :payments, only: [:new]
end