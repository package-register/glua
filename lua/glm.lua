-- GLM API 封装模块
-- 使用内置 http.stream + json 库调用智谱 GLM API
--
-- 用法:
--   local glm = require "glm"
--   glm.set_key(os.getenv("GLM_API_KEY"))
--   local resp = glm.ask("你好")
--   print(resp)

local glm = {}

local API_BASE = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
local DEFAULT_MODEL = "glm-5.1"
local api_key = ""

function glm.set_key(key)
  api_key = key
end

function glm.load_key_from_env(env_name)
  env_name = env_name or "GLM_API_KEY"
  local key = os.getenv(env_name)
  if key and key ~= "" then
    api_key = key
    return true
  end
  return false
end

function glm.load_key_from_file(path)
  path = path or os.getenv("HOME") .. "/.glm_key"
  local f, err = io.open(path, "r")
  if f then
    api_key = f:read("*a"):gsub("%s+", "")
    f:close()
    return true
  end
  return false
end

local function requires_key()
  if api_key == "" then
    error("GLM API key not set. Call glm.set_key() or glm.load_key_from_env()")
  end
end

local function build_headers()
  return {
    ["Authorization"] = "Bearer " .. api_key,
    ["Content-Type"] = "application/json",
  }
end

local function build_body(messages, opts)
  opts = opts or {}
  return {
    model = opts.model or DEFAULT_MODEL,
    messages = messages,
    temperature = opts.temperature or 0.95,
    top_p = opts.top_p or 0.7,
    max_tokens = opts.max_tokens or 4096,
    stream = opts.stream or false,
  }
end

function glm.message(role, content)
  return {role = role, content = content}
end

function glm.system(content)
  return glm.message("system", content)
end

function glm.user(content)
  return glm.message("user", content)
end

function glm.assistant(content)
  return glm.message("assistant", content)
end

-- The gopher-lua pcalling bug (issue #452) means we CANNOT pass
-- pcall-caught error objects through function calls.
-- Strategy: use protected calls only at the outermost layer.
-- Internal functions raise errors directly; glm.chat wraps in pcall.

function glm.chat(messages, opts)
  requires_key()
  if type(messages) == "string" then
    messages = {{role = "user", content = messages}}
  end
  local body = build_body(messages, opts)
  local headers = build_headers()
  local resp = http.post(API_BASE, json.encode(body), headers)
  if resp.status >= 400 then
    return nil, "HTTP error: " .. resp.status
  end
  local result = json.decode(resp.body)
  if not result then
    return nil, "json decode failed"
  end
  return result, nil
end

function glm.chat_stream(messages, on_chunk, opts)
  requires_key()
  if type(messages) == "string" then
    messages = {{role = "user", content = messages}}
  end
  opts = opts or {}
  opts.stream = true
  local body = build_body(messages, opts)
  local headers = build_headers()
  local full_text = ""
  http.stream("POST", API_BASE, json.encode(body), headers, function(err, data)
    if err then
      on_chunk(nil, err)
      return
    end
    if data == nil then
      on_chunk("", true)
      return
    end
    local chunk = json.decode(data)
    if not chunk then return end
    if chunk.choices and chunk.choices[1] then
      local delta = chunk.choices[1].delta
      if delta and delta.content then
        full_text = full_text .. delta.content
        on_chunk(delta.content, false)
      end
    end
  end)
  return full_text
end

function glm.ask(prompt, opts)
  requires_key()
  if type(prompt) ~= "string" then
    return nil, "prompt must be a string"
  end
  local resp, err = glm.chat(prompt, opts)
  if err then return nil, err end
  if resp and resp.choices and resp.choices[1] then
    return resp.choices[1].message.content, nil
  end
  return nil, "unexpected response format"
end

return glm
