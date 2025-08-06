# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # フロントエンドのドメインを指定
    origins []

    resource '/api/*', # APIのエンドポイントを指定
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end