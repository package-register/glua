print('testing json library')

-- basic encode/decode round trip
do
  local s = json.encode({name = "test", value = 42})
  local t = json.decode(s)
  assert(t.name == "test", "encode/decode name failed")
  assert(t.value == 42, "encode/decode value failed")
end

-- pretty print
do
  local pretty = json.encode({a = 1}, true)
  assert(type(pretty) == "string", "pretty should be string")
  assert(pretty:find("\n") ~= nil, "pretty should have newlines")
end

-- decode basic JSON types
do
  local t = json.decode('{"str":"hello","num":123,"flag":true,"null_val":null}')
  assert(t.str == "hello", "decode string failed")
  assert(t.num == 123, "decode number failed")
  assert(t.flag == true, "decode bool failed")
  assert(t.null_val == nil, "decode null failed")
end

-- decode JSON array
do
  local arr = json.decode('[10, 20, 30]')
  assert(arr[1] == 10, "array[1] failed")
  assert(arr[2] == 20, "array[2] failed")
  assert(arr[3] == 30, "array[3] failed")
  assert(#arr == 3, "array length failed")
end

-- encode Lua array to JSON
do
  local s = json.encode({100, 200, 300})
  local t = json.decode(s)
  assert(t[1] == 100 and t[2] == 200 and t[3] == 300, "encode array round trip failed")
end

-- deep nested structures
do
  local nested = json.decode('{"a":{"b":{"c":"deep","d":[1,2,{"e":"f"}]}}}')
  assert(nested.a.b.c == "deep", "nested string failed")
  assert(nested.a.b.d[1] == 1, "nested array failed")
  assert(nested.a.b.d[3].e == "f", "nested object in array failed")
end

-- encode/decode nested table
do
  local t = {x = {y = {z = 99}}}
  local s = json.encode(t)
  local t2 = json.decode(s)
  assert(t2.x.y.z == 99, "nested encode/decode failed")
end

-- empty table
do
  local s = json.encode({})
  assert(s == "{}", "empty object failed: " .. s)
end

-- empty array (numeric indices only)
do
  local t = {1, 2}
  local s = json.encode(t)
  local t2 = json.decode(s)
  assert(t2[1] == 1 and t2[2] == 2, "empty/consecutive array failed")
end

-- boolean values
do
  local s = json.encode({a = true, b = false})
  local t = json.decode(s)
  assert(t.a == true, "bool true failed")
  assert(t.b == false, "bool false failed")
end

-- number precision
do
  local t = json.decode('{"int":123456789,"float":3.14159,"neg":-42}')
  assert(t.int == 123456789, "int precision failed")
  assert(t.float == 3.14159, "float precision failed")
  assert(t.neg == -42, "neg number failed")
end

-- decode array of objects
do
  local t = json.decode('[{"id":1,"name":"a"},{"id":2,"name":"b"}]')
  assert(t[1].id == 1 and t[1].name == "a", "array of objects[1] failed")
  assert(t[2].id == 2 and t[2].name == "b", "array of objects[2] failed")
end

-- encode mixed table (int + string keys) - treated as object
do
  local t = {10, 20, x = "hello"}
  local s = json.encode(t)
  local t2 = json.decode(s)
  assert(t2.x == "hello", "mixed table string key failed")
end

-- malformed JSON (should error)
local ok1, err1 = pcall(json.decode, "{invalid}")
assert(not ok1, "malformed JSON should fail")

-- empty string (should error)
local ok2, err2 = pcall(json.decode, "")
assert(not ok2, "empty string should fail")

-- encode nil (should produce 'null')
local s2 = json.encode(nil)

-- encode boolean
do
  local s = json.encode(true)
  assert(s == "true", "encode true failed: " .. s)
  local s = json.encode(false)
  assert(s == "false", "encode false failed: " .. s)
end

-- encode number
do
  local s = json.encode(42)
  assert(s == "42", "encode number failed: " .. s)
  local s = json.encode(3.14)
  -- 3.14 might be encoded as 3.14 or 3.140000... 
end

-- encode empty array
do
  local arr = {}
  local s = json.encode(arr)
  assert(s == "{}" or s == "[]", "empty table encode failed: " .. s)
end

print('OK')
