# ベースイメージを指定
FROM ruby:3.4.4-slim

# 必要なパッケージをインストール
# - build-essential: gemのネイティブ拡張をビルドするために必要
# - libmariadb-dev: mysql2 gemのビルドに必要 (旧libmysqlclient-dev) ★変更
# - nodejs, yarn: JavaScriptのランタイムとパッケージ管理
# - libyaml-dev: psych gemのビルドに必要
# - git: GemfileでGitHubリポジトリを参照するために必要
RUN apt-get update -qq && apt-get install -y build-essential libmariadb-dev nodejs yarn libyaml-dev git imagemagick 

# 作業ディレクトリを作成
WORKDIR /myapp

# Gemfileをコンテナにコピー
COPY Gemfile Gemfile.lock ./

# Gemをインストール
RUN bundle install

# エントリーポイントスクリプトをコピーして実行権限を付与
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# デフォルトでコンテナが公開するポート
EXPOSE 3000

# メインプロセス（Railsサーバー）の起動コマンド
CMD ["rails", "server", "-b", "0.0.0.0"]