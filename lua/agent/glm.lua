-- agent/glm.lua — GLM API 封装（agent 专用版）
-- 自包含，不依赖外部文件

local glm = {}

local API_BASE = "https://open.bigmodel.cn/api/paas/v4/chat/completions"

function glm.new(key)
  local self = {api_key = key or "", model = "glm-5.1"}
  
  function self.chat(messages, opts)
    opts = opts or {}
    local body = {
      model = opts.model or self.model,
      messages = messages,
      temperature = opts.temperature or 0.1,
      max_tokens = opts.max_tokens or 4096,
      stream = opts.stream or false,
    }
    local headers = {
      Authorization = "Bearer " .. self.api_key,
      ["Content-Type"] = "application/json",
    }
    local resp = http.post(API_BASE, json.encode(body), headers)
    if resp.status >= 400 then
      return nil, "HTTP " .. resp.status
    end
    return json.decode(resp.body)
  end

  function self.ask(text, opts)
    local resp, err = self.chat({{role="user", content=text}}, opts)
    if err then return nil, err end
    if resp and resp.choices and resp.choices[1] then
      return resp.choices[1].message.content
    end
    return nil, "unexpected response"
  end

  function self.stream(messages, on_chunk, opts)
    opts = opts or {}
    opts.stream = true
    local body = {
      model = opts.model or self.model,
      messages = messages,
      temperature = opts.temperature or 0.1,
      max_tokens = opts.max_tokens or 4096,
      stream = true,
    }
    local headers = {
      Authorization = "Bearer " .. self.api_key,
      ["Content-Type"] = "application/json",
    }
    local full = ""
    http.stream("POST", API_BASE, json.encode(body), headers, function(err, data)
      if err then on_chunk(nil, err); return end
      if data == nil then on_chunk("", true); return end
      local chunk = json.decode(data)
      if chunk and chunk.choices and chunk.choices[1] then
        local d = chunk.choices[1].delta
        if d and d.content then
          full = full .. d.content
          on_chunk(d.content, false)
        end
      end
    end)
    return full
  end

  return self
end

return glm
