print('testing agent library')

-- agent module loads correctly
package.path = "../../lua/?.lua;../../lua/?/init.lua;../?.lua;../?/init.lua;" .. package.path
local agent = require("agent")

assert(type(agent) == "table", "agent should be a table")
assert(type(agent.run) == "function", "agent.run should be a function")

-- tools should be loadable
local tools = dofile("../../lua/agent/tools.lua")
assert(type(tools) == "table", "tools should be a table")
assert(type(tools.run) == "function", "tools.run should be a function")
assert(type(tools.read_file) == "function", "tools.read_file should be a function")
assert(type(tools.list_dir) == "function", "tools.list_dir should be a function")

-- config should be loadable
local config = dofile("../../lua/agent/config.lua")
assert(type(config) == "table", "config should be a table")
assert(type(config.init) == "function", "config.init should be a function")

-- glm module should be loadable
local glm = dofile("../../lua/agent/glm.lua")
assert(type(glm) == "table", "glm should be a table")
assert(type(glm.new) == "function", "glm.new should be a function")
local g = glm.new("test-key")
assert(type(g.ask) == "function", "g.ask should be a function")
assert(type(g.chat) == "function", "g.chat should be a function")
assert(type(g.stream) == "function", "g.stream should be a function")

-- test JSON tool_call format parsing
local encoded = json.encode({tool = "run", args = {"ls"}})
local decoded = json.decode(encoded)
assert(decoded.tool == "run", "tool name should be run")
assert(decoded.args[1] == "ls", "args[1] should be ls")

print('OK')
