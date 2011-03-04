Gknome::Application.routes.draw do
  root :to => "page#home"
  match '/about' => "page#about", :as => :about
end
