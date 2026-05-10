-- agent/demo.lua — Agent 能力演示
-- 运行: ./glua agent/demo.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

print("=== Agent 演示 ===\n")

-- 1. 加载 agent
local agent = require("agent")

-- 2. 执行任务
local task = "列出当前目录，找到最大的 .go 文件，告诉我它的文件名和大小"

print("任务: " .. task)
print("（正在执行，需调用 LLM 多次...）")
print()

local result = agent.run(task)

print()
print("=== 结果 ===")
print(result)
