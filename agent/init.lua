-- agent/init.lua — 最小 Agent Loop
-- 用法: local agent = require "agent"  (从项目根目录)

-- 兼容不同 CWD：尝试多个路径加载子模块
local function find_file(name)
  local paths = {
    "agent/" .. name,
    "../agent/" .. name,
    "./agent/" .. name,
    name,
  }
  for _, p in ipairs(paths) do
    local f = io.open(p, "r")
    if f then f:close(); return p end
  end
  return nil
end

local function load_module(name)
  local p = find_file(name)
  if not p then return nil end
  return dofile(p)
end

local config = load_module("config.lua")
local tools = load_module("tools.lua")
local glm_mod = load_module("glm.lua")

if not config or not tools or not glm_mod then
  error("agent: 无法加载子模块 — 请从项目根目录运行 ./glua agent/demo.lua")
end

-- ============================================================
-- 解析 LLM 回复中的 JSON
-- ============================================================

local function parse_json(text)
  local ok, r = pcall(json.decode, text)
  if ok then return r end

  for start in text:gmatch("()```json") do
    local _, finish = text:find("\n", start + 7)
    if finish then
      local end_pos = text:find("```", finish + 1)
      if end_pos then
        local ok2, r2 = pcall(json.decode, text:sub(finish + 1, end_pos - 1))
        if ok2 then return r2 end
      end
    end
  end

  local brace_start = text:find("{")
  if brace_start then
    local brace_end = text:find("}", brace_start, true)
    if brace_end then
      local ok3, r3 = pcall(json.decode, text:sub(brace_start, brace_end))
      if ok3 then return r3 end
    end
  end
  return nil
end

-- ============================================================
-- 调用 LLM
-- ============================================================

local function llm(glm, messages)
  io.write("[LLM] ")
  local full = ""
  glm.stream(messages, function(chunk, done)
    if chunk == nil then io.write("\n[错误] " .. tostring(done) .. "\n"); return end
    io.write(chunk)
    full = full .. chunk
  end)
  io.write("\n")
  return full
end

-- ============================================================
-- 执行工具
-- ============================================================

local function exec(call)
  local name, args
  if call.tool then
    name, args = call.tool, call.args or {}
  elseif call.tool_call then
    name, args = call.tool_call.name, call.tool_call.args or {}
  else
    return nil, "无法识别的工具调用格式"
  end
  local fn = tools[name]
  if not fn then
    local aliases = {execute = "run", list = "list_dir", find = "search", cat = "read_file"}
    fn = tools[aliases[name]]
  end
  if type(fn) ~= "function" then
    return nil, "未知工具: " .. tostring(name)
  end
  -- 直接调用（不用 table.unpack，避免 gopher-lua bug）
  local call_args = type(args) == "table" and args or (args ~= nil and {args} or {})
  local r
  if #call_args == 0 then r = fn()
  elseif #call_args == 1 then r = fn(call_args[1])
  elseif #call_args == 2 then r = fn(call_args[1], call_args[2])
  else r = fn(call_args[1], call_args[2], call_args[3]) end
  if r == nil then return nil, "工具无返回" end
  return r
end

-- ============================================================
-- 主循环
-- ============================================================

function agent_run(task, opts)
  opts = opts or {}

  -- 初始化配置
  config.init()
  if config.api_key == "" then
    return "错误: 未设置 GLM_API_KEY\n请执行: export GLM_API_KEY=\"你的key\""
  end

  local glm = glm_mod.new(config.api_key)
  local max_steps = opts.steps or 8
  local verbose = opts.verbose
  if verbose == nil then verbose = true end

  local messages = {
    {role = "system", content = tools.schema},
    {role = "user", content = task},
  }

  for step = 1, max_steps do
    if verbose then print("\n=== Step " .. step .. "/" .. max_steps .. " ===") end

    local raw = llm(glm, messages)
    local cmd = parse_json(raw)

    if not cmd then
      table.insert(messages, {role = "user",
        content = "JSON 格式错误。只返回 JSON: {\"tool\":\"name\",\"args\":[...]} 或 {\"answer\":\"...\"}"})
      goto next
    end

    if cmd.answer then
      if verbose then print("\n=== 完成 ===") end
      return cmd.answer
    end

    if cmd.tool or cmd.tool_call then
      local r, err = exec(cmd)
      local result
      if err then
        result = "工具执行失败: " .. err
        if verbose then print("  ✗ " .. result) end
      else
        local s = tostring(r)
        if #s > 1500 then s = s:sub(1, 1500) .. "\n... (truncated)" end
        result = "工具结果:\n" .. s
        if verbose then print("  ✓ (" .. #tostring(r) .. " bytes)") end
      end
      table.insert(messages, {role = "user", content = result})
    else
      table.insert(messages, {role = "user",
        content = "JSON 缺少 tool/answer 字段。格式: {\"tool\":\"name\",\"args\":[...]} 或 {\"answer\":\"...\"}"})
    end

    ::next::
  end

  return "达到最大步数 " .. max_steps
end

local agent = {run = agent_run}
return agent
