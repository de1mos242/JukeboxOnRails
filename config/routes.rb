JukeboxOnRails::Application.routes.draw do
  resources :rooms


  get "omniauth_callbacks/vkontakte"

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  resources :users, :only => [:index, :destroy]


  #resources :playlist_items

  #resources :songs
  #get "songs/index", :as => :songs


  match 'playlist_items' => 'playlist_items#index', :as => :playlist_items
  match 'playlist_items/stop' => 'playlist_items#stop', :as => :playlist_stop
  match 'playlist_items/skip' => 'playlist_items#skip', :as => :playlist_skip
  match 'playlist_items/volume' => 'playlist_items#change_volume', :as => :change_volume
  match 'playlist_items/update_current_song' => 'playlist_items#now_playing', :as => :update_now_playing

  match 'find(/:find_query)' => 'control_panel#index', as: :short_find_songs
  match 'songs/find' => 'songs#find', :as => :find_songs
  match 'songs/queue' => 'songs#add_to_playlist', :as => :add_to_playlist

  match "control_panel" => 'control_panel#index', as: :control_panel
  match "control_panel/find" => 'control_panel#find', as: :control_panel_find
  match "control_panel/refresh" => 'control_panel#refresh', as: :control_panel_refresh
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'control_panel#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
