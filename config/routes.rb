Spree::Core::Engine.add_routes do
  # Add your extension routes here

  Spree::Core::Engine.add_routes do
    post '/instamojo', :to => "instamojo#index", :as => :instamj_proceed
    get '/instamojo/confirm', :to => "instamojo#confirm", :as => :instamj_confirm
    post '/instamojo/cancel', :to => "instamojo#cancel", :as => :instamj_cancel
    post '/paytm', :to => "paytm#index", :as => :paytm_proceed
    post '/paytm/confirm', :to => "paytm#confirm", :as => :paytm_confirm
    post '/paytm/cancel', :to => "paytm#cancel", :as => :paytm_cancel
  end
end
