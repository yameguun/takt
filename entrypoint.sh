#!/bin/bash
set -e

# Railsのpidが残っている場合に削除する
rm -f /myapp/tmp/pids/server.pid

# データベースの作成とマイグレーションを実行する
# db:prepare は、DBがなければ作成し、マイグレーションを実行する便利なコマンド
# echo "Preparing database..."
# bundle exec rake db:prepare

# DockerfileのCMDで渡されたコマンドを実行する (rails sなど)
exec "$@"