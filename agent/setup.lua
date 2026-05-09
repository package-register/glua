-- agent/setup.lua — 环境检查 + 一键配置
-- 运行: ./glua agent/setup.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

print("=== Agent 环境检查 ===\n")

-- 1. 检查 GLM_API_KEY
local key = os.getenv("GLM_API_KEY")
if key and key ~= "" then
  print("[OK] GLM_API_KEY 已设置: " .. key:sub(1, 8) .. "...")
else
  print("[!!] GLM_API_KEY 未设置")
  print("     执行: export GLM_API_KEY=\"你的key\"")
end

-- 2. 检查代理
local proxy = os.getenv("HTTPS_PROXY") or os.getenv("https_proxy")
if proxy then
  print("[OK] HTTPS_PROXY = " .. proxy)
else
  proxy = os.getenv("HTTP_PROXY") or os.getenv("http_proxy")
  if proxy then
    print("[OK] HTTP_PROXY = " .. proxy)
  else
    print("[..] 未设代理，直连模式")
  end
end

-- 3. 测试 http 库
print("\n--- 测试内置库 ---")
print("[OK] http.get = " .. type(http.get))
print("[OK] json.encode = " .. type(json.encode))

-- 4. 测试 GLM API（如果 key 已设置）
if key and key ~= "" then
  print("\n--- 测试 GLM API ---")
  local glm = require("agent.glm")
  local g = glm.new(key)
  local resp, err = g.ask("用一句话验证连通性")
  if resp then
    print("[OK] GLM API 响应: " .. resp)
  else
    print("[!!] GLM API 失败: " .. tostring(err))
    print("     可能是代理问题，尝试: export HTTPS_PROXY=\"http://172.19.96.1:7897\"")
  end
end

print("\n=== 检查完成 ===")
