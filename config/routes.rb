Rails.application.routes.draw do
  root 'home#index'
  resources :ranking, only: [:index]
end
