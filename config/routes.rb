Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "welcome#index"

  get "login" => "sessions#new"
  post "login" => "sessions#create"
  delete "logout" => "sessions#destroy"

  patch "switch_company" => "sessions#switch_company", as: :switch_company

  get 'auth/slack', to: 'slack_authentications#new', as: 'slack_login'
  get 'auth/slack/callback', to: 'slack_authentications#create'

  # 日報を書く（コメント表示機能を追加）
  resources :daily_reports, only: [:index, :create], path: "/reports" do
    collection do
      get :previous_day_report
    end
    member do
      get :comments
    end
  end

  # カレンダー
  get 'calendar', to: 'calendars#show'

  # 残業承認画面とコメント機能
  namespace :manager do
    resources :overtime_requests, only: [:index] do
      member do
        patch :approve
      end
    end
    resources :daily_reports, only: [:index] do
      member do
        post :generate_ai_comment
      end
      resources :comments, only: [:create, :destroy]
    end
  end

  namespace :api do
    resources :clients, only: [:index]
    resources :projects, only: [:index]
    resources :task_types, only: [:index]
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
        resources :users, except: [:show] do
          member do
            delete :remove_avatar
          end
        end
        resources :departments, except: [:show]
        resources :clients, except: [:show] do
          resources :projects, except: [:show]
        end
        resources :task_types, except: [:show] do
          collection do
            post :import
            get :download_template
          end
        end
        resources :project_types, except: [:show] do
          collection do
            post :import
            get :download_template
          end
        end
      end
    end
  end
end