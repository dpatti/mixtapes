Mixtapes::Application.routes.draw do
  root :to => 'application#index'
  get '/home' => 'application#home'
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signout' => 'sessions#destroy', :as => :signout

  resources :users, :only => [:new, :create]

  resource :user do
    collection do
      get 'mixtapes'
      get 'favorites'
      get 'comments'
    end
  end

  resources :contests, :only => [:index] do
    resources :mixtapes, :only => [:index, :new, :create] do
      collection do
        get 'random', :action => 'listen_random'
      end
    end

    resources :songs, :only => [:index] do
      collection do
        get 'favorites'
      end
    end

    resource :guesses, :only => [:show, :update]
    resource :votes, :only => [:show, :update]

    member do
      get 'download'
    end
  end

  resources :mixtapes, :only => [:show, :update, :destroy] do
    resources :songs, :only => [:create]
    resources :comments, :only => [:create]

    member do
      get 'destroy', :as => 'destroy', :path => 'destroy', :action => 'destroy_confirm'
      get 'download'
      get 'listen'
      get 'visualize'
    end
  end

  resources :songs, :only => [:update, :destroy] do
    member do
      put 'like'
      get 'listen'
    end
  end

  resources :comments, :only => [:update, :destroy]
end
