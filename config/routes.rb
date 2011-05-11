Gknome::Application.routes.draw do
  resources :genomes

  root :to => "page#home"
  match '/about' => "page#about", :as => :about
  match '/genes' => "page#genes", :as => :genes
  match '/diseases' => "page#diseases", :as => :diseases
  match '/processes' => "page#processes", :as => :processes
  match '/summary' => "page#summary", :as => :summary
end
