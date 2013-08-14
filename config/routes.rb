Mixtapes::Application.routes.draw do

  root :to => 'application#index'

  match '/voting' => 'application#voting'

  match '/auth/:provider/callback' => 'sessions#create'
  match '/signout' => 'sessions#destroy', :as => :signout

  match '/songs' => 'songs#index'

  resource :guesses, :only => [:show, :update]

  resources :mixtapes, :except => :edit do
    resources :songs, :only => [:create, :update, :destroy] do
      member do
        put 'like'
      end
    end
    resources :comments, :only => [:create, :update, :destroy]

    collection do
      get 'download', :action => 'download_all'
    end

    member do
      get 'destroy', :as => 'destroy', :path => 'destroy', :action => 'destroy_confirm'
      get 'download'
      get 'listen'
    end
  end
end
