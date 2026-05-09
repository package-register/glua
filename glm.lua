-- GLM API 封装模块
-- 使用内置 http.stream + json 库调用智谱 GLM API
--
-- 用法:
--   local glm = require "glm"
--   glm.set_key(os.getenv("GLM_API_KEY"))
--   local resp = glm.chat("你好")
--   print(resp.choices[1].message.content)

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

local function check_key()
  -- NOTE: don't use error() + pcall to check key
  -- gopher-lua has a bug where pcall-caught error objects
  -- corrupt captured variables when passed through function calls
  return api_key ~= ""
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

function glm.chat(messages, opts)
  if not check_key() then
    return nil, "GLM API key not set. Call glm.set_key() or glm.load_key_from_env()"
  end
  if type(messages) == "string" then
    messages = {{role = "user", content = messages}}
  end
  local body = build_body(messages, opts)
  local headers = build_headers()
  local ok, resp = pcall(http.post, API_BASE, json.encode(body), headers)
  if not ok then
    return nil, tostring(resp)
  end
  if resp.status >= 400 then
    return nil, "HTTP " .. resp.status .. ": " .. (resp.body or "")
  end
  local ok4, result = pcall(json.decode, resp.body)
  if not ok4 then
    return nil, "json decode failed: " .. tostring(result)
  end
  return result, nil
end

function glm.chat_stream(messages, on_chunk, opts)
  if not check_key() then
    on_chunk(nil, "GLM API key not set. Call glm.set_key() or glm.load_key_from_env()")
    return ""
  end
  if type(messages) == "string" then
    messages = {{role = "user", content = messages}}
  end
  opts = opts or {}
  opts.stream = true
  local body = build_body(messages, opts)
  local headers = build_headers()
  local full_text = ""
  pcall(http.stream, "POST", API_BASE, json.encode(body), headers, function(err, data)
    if err then
      on_chunk(nil, err)
      return
    end
    if data == nil then
      on_chunk("", true)
      return
    end
    local ok3, chunk = pcall(json.decode, data)
    if not ok3 then return end
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
  local resp, err = glm.chat(prompt, opts)
  if err then return nil, err end
  if resp.choices and resp.choices[1] then
    return resp.choices[1].message.content, nil
  end
  return nil, "unexpected response format"
end

return glm
