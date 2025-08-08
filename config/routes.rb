Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "welcome#index"

  get "login" => "sessions#new"
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy"

  get 'auth/slack', to: 'slack_authentications#new', as: 'slack_login'
  get 'auth/slack/callback', to: 'slack_authentications#create'

  # 日報を書く
  resources :daily_reports, only: [:index, :create], path: "/reports"

  # 残業承認画面
  resources :overtime_requests, only: [:index] do
    member do
      patch :approve
    end
  end

  namespace :api do
    resources :clients, only: [:index]
    resources :projects, only: [:index]
    resources :daily_report_projects do
      member do
        post :request_overtime
        delete :cancel_overtime
      end
    end
  end

  # 管理者
  namespace :admin do
    root "dashboard#index"
    get "login" => "sessions#new"
    post "login" => "sessions#create"
    delete "logout" => "sessions#destroy"
    scope module: :company do
      resources :companies, except: [:show] do
        resources :users, except: [:new, :create, :show]
        resources :departments, except: [:show]
        resources :clients, except: [:show] do
          resources :projects, except: [:show]
        end
      end
    end
  end
end