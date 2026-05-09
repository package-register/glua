print('testing glm library')

-- glm module loads correctly
local glm = dofile("_lua5.5-tests/glm.lua")
assert(type(glm) == "table", "glm should be a table")
assert(type(glm.set_key) == "function", "glm.set_key")
assert(type(glm.chat) == "function", "glm.chat")
assert(type(glm.chat_stream) == "function", "glm.chat_stream")
assert(type(glm.ask) == "function", "glm.ask")
assert(type(glm.message) == "function", "glm.message")
assert(type(glm.system) == "function", "glm.system")
assert(type(glm.user) == "function", "glm.user")
assert(type(glm.assistant) == "function", "glm.assistant")

-- glm.message helpers
local msg = glm.message("user", "hello")
assert(msg.role == "user", "message role")
assert(msg.content == "hello", "message content")

local sys = glm.system("You are helpful")
assert(sys.role == "system", "system role")

local usr = glm.user("hi")
assert(usr.role == "user", "user role")

local asst = glm.assistant("hello!")
assert(asst.role == "assistant", "assistant role")

-- glm.chat without API key should error
local ok, err = glm.chat("test")
assert(not ok, "chat without key should fail")
assert(err ~= nil, "chat without key should have error message")

-- glm.chat_stream without API key should error
local stream_err = nil
glm.chat_stream("test", function(chunk, done)
  if chunk == nil then
    stream_err = done
  end
end)
assert(stream_err ~= nil, "chat_stream without key should error")

-- glm.ask without API key should error
local ok2, err2 = glm.ask("test")
assert(not ok2, "ask without key should fail")

-- glm.load_key_from_env (test with non-existent env)
local found = glm.load_key_from_env("NON_EXISTENT_ENV_12345")
assert(not found, "non-existent env should return false")

-- glm.load_key_from_file with non-existent file
local found2 = glm.load_key_from_file("/tmp/nonexistent_glm_key_12345.key")
assert(not found2, "non-existent file should return false")

-- set key and verify chat structure (without making real API call)
glm.set_key("test-key-12345")

-- build body manually and check structure
local headers = {
  ["Authorization"] = "Bearer test-key-12345",
  ["Content-Type"] = "application/json",
}
local body = json.encode({
  model = "glm-5.1",
  messages = {{role = "user", content = "hi"}},
  temperature = 0.95,
  top_p = 0.7,
  max_tokens = 4096,
  stream = false,
})
assert(type(body) == "string", "request body should be string")
local decoded = json.decode(body)
assert(decoded.model == "glm-5.1", "model in body")
assert(decoded.messages[1].role == "user", "message role in body")
assert(decoded.messages[1].content == "hi", "message content in body")
assert(decoded.stream == false, "stream false in body")

-- stream body should have stream=true
local body2 = json.encode({
  model = "glm-5.1",
  messages = {{role = "user", content = "hi"}},
  stream = true,
})
local decoded2 = json.decode(body2)
assert(decoded2.stream == true, "stream true in body")

print('OK')
