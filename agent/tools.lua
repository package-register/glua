-- agent/tools.lua — 9 原子工具集

local tools = {}

function tools.read_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, "cannot read: " .. tostring(err) end
  local c = f:read("*a")
  f:close()
  return c
end

function tools.write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then return nil, "cannot write: " .. tostring(err) end
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

function tools.run(cmd)
  local f = io.popen(cmd, "r")
  if not f then return nil, "exec error" end
  local r = f:read("*a")
  f:close()
  return r
end
tools.execute = tools.run  -- alias

function tools.search(name)
  local cmd = 'find . -type f -name "' .. name .. '" 2>/dev/null | head -30'
  local f = io.popen(cmd, "r")
  if not f then return "(no tool)" end
  local r = f:read("*a")
  f:close()
  if r == "" then return "(no matches)" end
  return r
end

function tools.grep(text, path)
  path = path or "."
  local cmd = 'grep -rn "' .. text .. '" ' .. path .. ' 2>/dev/null | head -30'
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
  if resp.status >= 400 then
    return nil, "HTTP " .. resp.status
  end
  return resp.body
end

function tools.now()
  return os.date("%Y-%m-%d %H:%M:%S")
end

function tools.pwd()
  return io.popen("pwd"):read("*a"):gsub("%s+", "")
end

-- 工具描述（给 LLM 的 JSON Schema）
tools.schema = [[
你是一个文件系统助手。可用工具：

1. read_file(path)           — 读取文件
2. write_file(path,content)  — 写入文件
3. list_dir(path)            — 列出目录（默认 .）
4. run(cmd)                  — 执行 shell 命令
5. search(name)              — 按文件名搜索（glob）
6. grep(text, path?)         — 搜索文件内容
7. http_get(url)             — 获取 URL 内容
8. now()                     — 当前时间
9. pwd()                     — 当前目录

回复必须是 JSON，只返回 JSON 不要其他文字：

{"tool":"run","args":["ls -la"]}
{"answer":"这是最终结果"}

注意: tool 的名字必须是上面列表中的之一。先理解任务，选一个工具，然后用 JSON 格式回复。
]]

return tools
