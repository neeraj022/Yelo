Rails.application.routes.draw do

  get 'public/index'

  devise_for :users
  root 'public#index'

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
      post "/send_missed_call", to: "users#send_missed_call"
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
      get "/users/:user_id/walls", to: 'walls#user_walls'
      post "/push_records/:id/seen", to: "push_records#update_seen_status"
      get "/push_records", to: "push_records#index"
      get "/users/:user_id/all_tags", to: "tags#all_user_tags"
      get "/walls/:id/connects", to: "walls#connects"
      post "/walls/:id/close", to: "walls#wall_close"
      post "/abuse", to: "users#abuse"
      post "/walls/:id/destroy", to: "walls#destroy"
      post "/users/contacts", to: "users#contacts"
      post "/users/contacts_and_names", to: "users#contacts_with_name"
      get "/shares/:mobile_number", to: "public#shares"
      get "/push", to: "public#push"
      get "/users/chats", to: "chats#user_chats"
      get "/users/:user_id/recommends/tags", to: "users#tag_recommends"
      get "/users/:user_id/recommendations/tags", to: "users#tag_recommendations"
      get "/users/:user_id/recommends", to: "users#recommends"
      get "/users/:user_id/recommendations", to: "users#recommendations"
      post "/sms_share", to: "users#sms_share"
      get  "/suggestions", to: "community#suggestions"
      get  "/tag_list/:group_id", to: "community#tag_list"
      get  "/group_list", to: "community#group_list"
      get  "/group_cards", to: "community#group_cards"
      get  "/top_tags", to: "community#top_tags"
      get  "/ping", to: "users#ping"
      get  "/users/claim", to: "users#claim"
      get  "/users/friend_referral_score", to: "users#friend_referral_score"
      get "/users/top_week_recommends", to: "users#top_week_recommends"
      post "/users/doc", to: "users#save_doc"
      get "/users/:user_id/service_cards", to: "service_cards#user_service_cards"
      get "/listing_service_cards/:listing_id", to: "service_cards#listing_service_cards"
      get "/service_cards/:service_card_id/ratings", to: "ratings#service_card_reviews"
      post "/ratings/:id/status", to: "ratings#rating_status"
      post "/service_cards/:id/destroy", to: "service_cards#destroy"
      post "/listings/:id/destroy", to: "listings#destroy"
      post "/ratings/:id/destroy", to: "ratings#destroy"
      post "/service_cards/:id/book/", to: "service_cards#book"
      post "/service_cards/:id/views", to: "service_cards#add_views"
      post "/walls/:wall_id/comments/:id/spam", to:"comments#report_spam"
      post "/walls/:wall_id/comments/:id/destroy", to: "comments#destroy"
      get "/walls/:id/wall_and_comments", to: "walls#wall_and_comments"
      get "/users/chat_users"
      get "users/calculate_points"
      get "/users/leaderboard"
      #added by neeraj
      #Method to get new suggestions according to tag field
      get "/booking_suggestions/:booking_id", to: "service_cards#get_top_suggestions"
      get "/service_cards/:service_card_id/ratings_pagination", to: "ratings#service_card_reviews_pagination"

      resources :users
      resources :ratings
      resources :listings
      resources :tags
      resources :service_cards
      resources :walls do
        resources :wall_items
        resources :comments
      end
    end
  end

  namespace :administrator do
    get "/statistics/index", to: "statistics#index"
    get "/wall/statistics", to: "statistics#wall_statistics"
    get "/walls/tags", to: "statistics#tag_summary"
    get "/statistics/users", to: "statistics#user_summary"
    get "/statistics/content_count", to: "new_content_statistics#index"
    resources :service_cards
  end

    mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

end
