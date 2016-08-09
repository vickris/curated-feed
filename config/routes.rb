Rails.application.routes.draw do
  #create routes for editing and updating user interests
  resources :users, only: [:edit, :update]

  devise_for :users, controllers: { registrations: "registrations" }
  #create routes for performing all CRUD operations on posts
  resources :posts

  #For authenticated users the root_path maps to the feed action of the posts_controller
  authenticated :user do
    root 'posts#feed', as: "authenticated_root"
  end

  root 'posts#index'
end
