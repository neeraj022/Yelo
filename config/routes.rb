Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  namespace :api do
    namespace :v1, defaults:{format: 'json'} do
      post "/verify_call", to: "users#verify_missed_call"
      post "/verify_serial_code", to: "users#verify_serial_code"
      post "/sms_serial_code", to: "users#sms_serial_code"
      post "/interests", to: "users#interests"
      get "/tags/suggestions", to: "tags#suggestions"
      get "/tags/auto_suggestions", to: "tags#auto_suggestions"
      get "/users/:id/listings", to: "listings#user_listings"
      get  "/search", to: "search#search"
      post '/chats/send', to: "chats#send_chat"
      post '/chats/status', to: "chats#set_status"
      post '/chats/seen', to: "chats#set_seen"
      get '/notify', to: "chats#notify"
      get "/server_status", to: "public#server_status"
      post '/referral', to: 'users#register_referral'
      get "/users/:user_id/ratings", to: 'ratings#user_ratings'
      get "/users/:user_id/walls", to: 'walls#user_walls'
      post "/notifications/:id/seen", to: "notifications#update_seen_status"
      get "/notifications", to: "notifications#index"
      get "/users/:user_id/all_tags", to: "tags#all_user_tags"
      get "/walls/:id/connects", to: "walls#connects"
      post "/walls/:id/close", to: "walls#wall_close"
      post "/abuse", to: "users#abuse"
      resources :users
      resources :ratings
      resources :listings
      resources :tags
      resources :walls do
        resources :wall_items
      end
    end
  end

end
