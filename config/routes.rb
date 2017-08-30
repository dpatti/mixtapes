Mixtapes::Application.routes.draw do

  root :to => 'application#index'

  get '/home' => 'application#home'

  get '/auth/:provider/callback' => 'sessions#create'
  get '/signout' => 'sessions#destroy', :as => :signout

  get '/songs' => 'songs#index'

  get '/songs/favorites' => 'songs#favorites'

  resources :users, :only => [:new, :create]

  resource :guesses, :only => [:show, :update]
  resource :votes, :only => [:show, :update]

  resources :mixtapes, :except => :edit do
    resources :songs, :only => [:create, :update, :destroy] do
      member do
        put 'like'
        get 'listen'
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
      get 'visualize'
    end
  end
end
