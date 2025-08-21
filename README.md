# README
工数管理ツール TAKT

## 本番環境
[https://takt.minigx.com](https://takt.minigx.com)

```bash
ssh debian@116.80.47.35
rake assets:precompile assets:clean
sudo systemctl restart puma.service
sudo systemctl restart solid_queue.service
```

```bash
rake db:migrate:queue
```