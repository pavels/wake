Rails.application.routes.draw do
  
  resources :things
  resources :pieces
  
  
  root :to=>'things#index'

  #mount Wake::Engine => "/wake"
end
