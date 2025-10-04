require "json"
require "faraday"
require "pry"
require "dotenv/load"

require_relative "./summarize_response"


p 'start'

# URL
URL = "https://api.openai.com"
ENDPOINT = "/v1/responses"

# Model
MODEL = "gpt-5-nano"
MAX_OUTPUT_TOKENS = 10_000
TEMPATURE = 0.2 # ランダム性(0.0~1.0)
SEED = 1 # 再現性

conn = Faraday.new(url: URL) { |f| f.request :json; f.response :json }

res = conn.post(ENDPOINT) do |r|
  r.headers["Authorization"] = "Bearer #{ENV["OPENAI_API_KEY"]}"
  r.headers["Content-Type"]  = "application/json"
  r.body = {
    model: MODEL,
    input: ARGV[0],
    max_output_tokens: MAX_OUTPUT_TOKENS,
    # temperature: TEMPATURE
  }
end

p '--------------'
p res.body['output'].last['content'].first['text']
p '--------------'

pp summarize_openai_response(res)
