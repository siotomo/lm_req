# 意識しておいた方がいいresponseだけ抽出
def summarize_openai_response(resp)
  env  = resp.env
  hdr  = env.response_headers || {}
  body = env.response_body

  # Faradayのmiddleware次第で body が String のこともあるので吸収
  if body.is_a?(String)
    require "json"
    body = JSON.parse(body) rescue {"parse_error" => true, "raw" => body}
  end

  # output から "message" を探して text を連結
  output_texts =
    Array(body.dig("output")).select { _1["type"] == "message" }
                             .flat_map { _1["content"] }
                             .select   { _1["type"] == "output_text" }
                             .map      { _1["text"] }

  # request body（JSON文字列）から主要パラメータを拾う
  req_body = env.request_body
  req_json = begin
    req_body.is_a?(String) ? JSON.parse(req_body) : req_body
  rescue
    {}
  end

  {
    # 1) HTTPメソッド & URL
    method: env.method,
    url:    env.url.to_s,

    # 2) リクエストBodyの要点
    request: {
      model:            req_json["model"],
      max_output_tokens: req_json["max_output_tokens"],
      input_preview:    (req_json["input"] || "").to_s[0, 80], # 先頭80字だけ
      input_length:     (req_json["input"] || "").to_s.length
    },

    # 3) リクエストHeaderの要点
    request_headers: {
      content_type: env.request_headers["Content-Type"],
      authorization_present: !!env.request_headers["Authorization"]
    },

    # 4) HTTPステータス
    http_status: env.status,
    http_reason: env.reason_phrase,

    # 5) OpenAI処理時間
    processing_ms: hdr["openai-processing-ms"]&.to_i,

    # 6) リクエストID
    request_id: hdr["x-request-id"],

    # 7) レート制限
    rate_limit: {
      limit_requests:     hdr["x-ratelimit-limit-requests"]&.to_i,
      remaining_requests: hdr["x-ratelimit-remaining-requests"]&.to_i,
      reset_requests:     hdr["x-ratelimit-reset-requests"],
      limit_tokens:       hdr["x-ratelimit-limit-tokens"]&.to_i,
      remaining_tokens:   hdr["x-ratelimit-remaining-tokens"]&.to_i,
      reset_tokens:       hdr["x-ratelimit-reset-tokens"]
    },

    # 8) レスポンス本体の成否
    response_status: body["status"],
    incomplete_reason: body.dig("incomplete_details", "reason"),

    # 9) モデル識別子
    model: body["model"],

    # 10) 出力テキスト & 使用トークン
    output: {
      text: output_texts.join("\n"),
      usage: {
        input_tokens:  body.dig("usage", "input_tokens"),
        output_tokens: body.dig("usage", "output_tokens"),
        total_tokens:  body.dig("usage", "total_tokens"),
        reasoning_tokens: body.dig("usage", "output_tokens_details", "reasoning_tokens")
      }
    }
  }
end
