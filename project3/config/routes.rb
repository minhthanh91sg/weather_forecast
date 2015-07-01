Rails.application.routes.draw do


  get 'weather/prediction/:post_code/:period', to: 'prediction#post_code_period', :post_code => /[0-9]+/, :period => /[0-9]+/, defaults: { format: 'json' }

  get 'weather/prediction/:lat/:long/:period',to: 'prediction#lat_long_period', :lat => /\-*\d+.\d+/ , :long => /\-*\d+.\d+/, :period => /[0-9]+/, defaults: { format: 'json' }

  #get 'data/locations'
  get 'weather/locations', to: 'data#locations', defaults: { format: 'json' }

  get 'weather/data/:location_id/:date', :location_id => /[A-Za-z][\w\s]+/, to: 'data#location_id_date', defaults: { format: 'json' }

  get 'weather/data/:post_code/:date', :post_code => /[0-9]+/, to: 'data#post_code_date', defaults: { format: 'json' }

  #get 'data/post_code'
  
  #resources :data, only: [:location]
  # resources :data do
  #   member do
  #     get :location
  #     get :location_id
  #     get :post_code
  #   end
  # end


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
end
