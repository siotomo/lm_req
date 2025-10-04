require "json"
require "faraday"
require "pry"

p 'start'

conn = Faraday.new(url: "https://api.openai.com") { |f| f.request :json; f.response :json }

res = conn.post("/v1/responses") do |r|
  r.headers["Authorization"] = "Bearer #{ENV["OPENAI_API_KEY"]}"
  r.headers["Content-Type"]  = "application/json"
  r.body = { model: "gpt-5-mini", input: "短歌を1つ" }
end

puts res.body.dig("output", 0, "content", 0, "text")
