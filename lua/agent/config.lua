-- agent/config.lua — 配置管理
-- 加载 API Key 和代理配置

local config = {}

config.api_key = ""

-- 从环境变量加载 API Key
function config.load_key(env_name)
  env_name = env_name or "GLM_API_KEY"
  local key = os.getenv(env_name)
  if key and key ~= "" then
    config.api_key = key
    return true
  end
  return false
end

-- 从文件加载 API Key (~/.glm_key)
function config.load_key_file(path)
  path = path or os.getenv("HOME") .. "/.glm_key"
  local f = io.open(path, "r")
  if f then
    config.api_key = f:read("*a"):gsub("%s+", "")
    f:close()
    return true
  end
  return false
end

-- 一键初始化
function config.init()
  return config.load_key() or config.load_key_file()
end

return config
