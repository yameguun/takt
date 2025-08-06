json.set! :clients do
  json.array! @clients do |client|
    json.extract! client, :id, :name
  end
end