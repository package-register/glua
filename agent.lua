-- agent.lua — 代理加载 agent/init.lua
-- 运行: local agent = require "agent"
package.path = "./?.lua;./?/init.lua;" .. package.path
return require("agent.init")
