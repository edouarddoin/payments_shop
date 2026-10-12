Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'products#index'

  resources :products, only: [:index, :show, :new]

  resources :orders, only: [:show, :create, :validate, :update] do
    collection do
      post :pay
    end
  end
  
  resources :payments, only: [:new]
end