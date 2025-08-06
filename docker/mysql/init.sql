-- `docker-compose.yml`で作成される'user'に全ての権限を付与する
-- これにより、Railsから'takt_test'データベースを作成できるようになる
GRANT ALL PRIVILEGES ON *.* TO 'user'@'%';

-- `takt_test`データベースも念のため作成しておく
CREATE DATABASE IF NOT EXISTS takt_test;