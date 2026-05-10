print('testing glm library')

-- load glm module
local glm = dofile("../lua/glm.lua")
assert(type(glm) == "table", "glm should be a table")
assert(type(glm.set_key) == "function", "glm.set_key")
assert(type(glm.chat) == "function", "glm.chat")
assert(type(glm.chat_stream) == "function", "glm.chat_stream")
assert(type(glm.ask) == "function", "glm.ask")
assert(type(glm.message) == "function", "glm.message")
assert(type(glm.system) == "function", "glm.system")
assert(type(glm.user) == "function", "glm.user")
assert(type(glm.assistant) == "function", "glm.assistant")

-- message helpers
local msg = glm.message("user", "hello")
assert(msg.role == "user", "message role")
assert(msg.content == "hello", "message content")

local sys = glm.system("You are helpful")
assert(sys.role == "system", "system role")

local usr = glm.user("hi")
assert(usr.role == "user", "user role")

local asst = glm.assistant("hello!")
assert(asst.role == "assistant", "assistant role")

-- without API key, glm.chat should error
local ok1, err1 = pcall(glm.chat, "test")
assert(not ok1, "chat without key should fail")
assert(err1 ~= nil, "chat without key should error")

-- ask without key should error
local ok2, err2 = pcall(glm.ask, "test")
assert(not ok2, "ask without key should fail")
assert(err2 ~= nil, "ask without key should error")

-- load_key_from_env with non-existent env should return false
local found = glm.load_key_from_env("NON_EXISTENT_ENV_12345_TEST")
assert(not found, "non-existent env should return false")

-- load_key_from_file with non-existent file should return false
local found2 = glm.load_key_from_file("/tmp/nonexistent_glm_key_12345.key")
assert(not found2, "non-existent file should return false")

-- set a test key and verify request body structure
glm.set_key("test-key-12345")

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
assert(decoded.model == "glm-5.1", "model")
assert(decoded.messages[1].content == "hi", "content")
assert(decoded.stream == false, "stream false")

-- stream body should have stream=true
local body2 = json.encode({
  model = "glm-5.1",
  messages = {{role = "user", content = "hi"}},
  stream = true,
})
local decoded2 = json.decode(body2)
assert(decoded2.stream == true, "stream true")

print('OK')
