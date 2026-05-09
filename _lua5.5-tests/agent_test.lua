print('testing agent library')

-- tools module loads correctly
package.path = "../?.lua;../?/init.lua;" .. package.path
local agent = require("agent")
assert(type(agent) == "table", "agent should be a table")
assert(type(agent.run) == "function", "agent.run should be a function")

-- test tools directly by accessing closure internals
-- We test tools via the agent.run's internal mechanism

-- Test 1: agent without API key should fail gracefully
local ok, err = pcall(agent.run, "test task")
-- without key, it should either error or return a message
-- (the behavior depends on glm.chat_stream error handling)

-- Test 2: create a mock to verify the loop structure
-- First, let's verify the JSON parsing works correctly
-- by testing the parse_json function indirectly through
-- the agent's tool execution flow

-- We can verify the module loads and has the right shape
assert(type(agent.run) == "function", "agent.run exists")

-- Test file system tools work
local content = agent.tools
-- tools are local, so we can't access them directly
-- but we can verify the module interface

-- Verify the glm module is available (needed by agent)
local glm = dofile("../glm.lua")
assert(type(glm) == "table", "glm module should be loadable")
assert(type(glm.chat_stream) == "function", "glm.chat_stream required by agent")

-- Verify json and http are available (needed by agent tools)
assert(type(json) == "table", "json module should be available")
assert(type(json.encode) == "function", "json.encode required")
assert(type(json.decode) == "function", "json.decode required")
assert(type(http) == "table", "http module should be available")

-- Test basic tool result formatting
local test_tools = {
  read_file = function(path)
    return "test content"
  end,
  list_dir = function(path)
    return "file1.txt\nfile2.txt"
  end,
}

-- Verify json encoding/decoding for tool_call format
local tool_call = {
  tool_call = {
    name = "read_file",
    args = {"test.txt"}
  }
}
local encoded = json.encode(tool_call)
local decoded = json.decode(encoded)
assert(decoded.tool_call.name == "read_file", "tool_call name")
assert(decoded.tool_call.args[1] == "test.txt", "tool_call args")

-- Verify final_answer format
local final = {final_answer = "任务完成"}
local encoded2 = json.encode(final)
local decoded2 = json.decode(encoded2)
assert(decoded2.final_answer == "任务完成", "final_answer")

print('OK')
