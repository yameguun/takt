client = Client.create(
  company: Company.all.first,
  name: "テストクライアント"
)

client.projects.create(name: "テストプロジェクト", sales: 10000)