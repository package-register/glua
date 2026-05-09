-- agent.lua — 最小 Agent Loop
-- 灵感来自 GenericAgent (github.com/lsdefine/GenericAgent)
-- ~100 行核心循环 + 9 原子工具
--
-- 用法:
--   local agent = require "agent"
--   agent.run("列出当前目录的文件")

local agent = {}

-- ============================================================
-- 原子工具集 (9 tools)
-- ============================================================

local tools = {}

function tools.read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, "read error: " .. tostring(err) end
  local c = f:read("*a")
  f:close()
  return c
end

function tools.write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then return nil, "write error: " .. tostring(err) end
  f:write(content)
  f:close()
  return "ok"
end

function tools.list_dir(path)
  local cmd = "ls -la " .. (path or ".")
  local f = io.popen(cmd, "r")
  if not f then return nil, "list error" end
  local r = f:read("*a")
  f:close()
  return r
end

function tools.execute(cmd)
  local f = io.popen(cmd, "r")
  if not f then return nil, "exec error" end
  local r = f:read("*a")
  f:close()
  return r
end

function tools.search_files(pattern)
  local cmd = "find . -type f -name '" .. pattern .. "' 2>/dev/null | head -50"
  local f = io.popen(cmd, "r")
  if not f then return nil, "search error" end
  local r = f:read("*a")
  f:close()
  if r == "" then return "(no matches)" end
  return r
end

function tools.grep(pattern, path)
  path = path or "."
  local cmd = "grep -rn '" .. pattern .. "' " .. path .. " 2>/dev/null | head -30"
  local f = io.popen(cmd, "r")
  if not f then return nil, "grep error" end
  local r = f:read("*a")
  f:close()
  if r == "" then return "(no matches)" end
  return r
end

function tools.http_get(url)
  local ok, resp = pcall(http.get, url)
  if not ok then return nil, resp end
  if resp.status >= 400 then return nil, "HTTP " .. resp.status end
  return resp.body
end

function tools.json_decode(str)
  local ok, r = pcall(json.decode, str)
  if not ok then return nil, r end
  return r
end

function tools.json_encode(val)
  local ok, r = pcall(json.encode, val)
  if not ok then return nil, r end
  return r
end

-- 工具描述（给 LLM 看的 Schema）
local tool_descriptions = [[
你是一个文件系统助手。你可以使用以下工具，每次返回一个 JSON 格式的 tool_call：

可用工具:

1. read_file(path) — 读取文件内容
2. write_file(path, content) — 写入文件
3. list_dir(path) — 列出目录 (默认 ".")
4. execute(cmd) — 执行 shell 命令
5. search_files(pattern) — 按文件名搜索 (glob 模式)
6. grep(pattern, path?) — 在文件中搜索文本
7. http_get(url) — GET 请求获取 URL 内容
8. json_decode(str) — 解析 JSON 字符串
9. json_encode(val) — 序列化为 JSON 字符串

返回格式: 每次回复必须是一个 JSON 对象，要么包含 tool_call 要么包含 final_answer。

调用工具:
{"tool_call": {"name": "read_file", "args": ["path/to/file.txt"]}}

完成回答:
{"final_answer": "这是最终结果。"}

如果你需要多次调用工具，一次只调用一个，我会把结果给你。
]]

-- ============================================================
-- 核心 Agent Loop (~80 行)
-- ============================================================

-- 解析 LLM 回复中的 JSON
local function parse_json(text)
  -- 尝试直接解析
  local ok, r = pcall(json.decode, text)
  if ok then return r end

  -- 尝试从 ```json ... ``` 块中提取
  local start, finish = text:find("```json")
  if start then
    local end_pos = text:find("```", finish + 1)
    if end_pos then
      local json_str = text:sub(finish + 1, end_pos - 1)
      local ok2, r2 = pcall(json.decode, json_str)
      if ok2 then return r2 end
    end
  end

  -- 尝试从 { 到 } 提取
  local brace_start = text:find("{")
  if brace_start then
    local brace_end = text:find("}", brace_start, true)
    if brace_end then
      local json_str = text:sub(brace_start, brace_end)
      local ok3, r3 = pcall(json.decode, json_str)
      if ok3 then return r3 end
    end
  end
  return nil
end

-- 执行工具调用
local function execute_tool(name, args)
  local fn = tools[name]
  if not fn then return nil, "unknown tool: " .. tostring(name) end
  local ok, r = pcall(fn, table.unpack(args or {}))
  if not ok then return nil, tostring(r) end
  return r
end

-- 执行单次 LLM 调用
local function llm_call(messages)
  local full = ""
  glm.chat_stream(messages, function(chunk, done)
    if chunk == nil then
      return
    end
    if done then return end
    full = full .. chunk
    io.write(chunk)
  end, {temperature = 0.1})
  io.write("\n")
  return full
end

-- 主循环
function agent.run(task, opts)
  opts = opts or {}
  glm.load_key_from_env("GLM_API_KEY")

  local messages = {
    {role = "system", content = tool_descriptions},
    {role = "user", content = task},
  }

  local max_steps = opts.max_steps or 10
  local verbose = opts.verbose
  if verbose == nil then verbose = true end

  for step = 1, max_steps do
    if verbose then print("\n=== Step " .. step .. " ===") end

    -- 调用 LLM
    local response = llm_call(messages)

    -- 解析 JSON 回复
    local parsed = parse_json(response)

    if not parsed then
      messages[#messages + 1] = {
        role = "user",
        content = "错误：无法从你的回复中解析 JSON。请只返回 JSON 格式。"
      }
      goto continue
    end

    -- 检查是否为 final answer
    if parsed.final_answer then
      if verbose then print("\n=== 最终结果 ===") end
      return parsed.final_answer
    end

    -- 检查是否为 tool_call
    if parsed.tool_call then
      local tc = parsed.tool_call
      local name = tc.name
      local args = tc.args or {}

      if verbose then
        print("→ 工具: " .. name .. "(" .. json.encode(args) .. ")")
      end

      local result, err = execute_tool(name, args)

      -- 将结果追加到对话
      local result_msg = ""
      if err then
        result_msg = "工具执行失败: " .. err
        if verbose then print("  ✗ " .. result_msg) end
      else
        -- 截断过长结果
        local result_str = tostring(result)
        if #result_str > 2000 then
          result_str = result_str:sub(1, 2000) .. "\n... (truncated)"
        end
        result_msg = "工具执行成功，结果:\n" .. result_str
        if verbose then print("  ✓ (len=" .. #tostring(result) .. ")") end
      end

      messages[#messages + 1] = {
        role = "user",
        content = result_msg
      }

      goto continue
    end

    -- 无法识别的格式
    messages[#messages + 1] = {
      role = "user",
      content = "无法识别的 JSON 格式。请使用 {tool_call: {name: ..., args: [...]}} 或 {final_answer: \"...\"}"
    }

    ::continue::
  end

  return "已达到最大步骤数 (" .. max_steps .. ")"
end

return agent
