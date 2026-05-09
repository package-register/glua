print('testing json library')

-- json.encode basic
local s = json.encode({name = "test", value = 42})
local t = json.decode(s)
assert(t.name == "test", "encode/decode name failed")
assert(t.value == 42, "encode/decode value failed")

-- json.encode pretty
local pretty = json.encode({a = 1}, true)
assert(type(pretty) == "string", "pretty should be string")
assert(#pretty > 10, "pretty should have whitespace")

-- json.decode basic types
local t2 = json.decode('{"str":"hello","num":123,"flag":true,"null_val":null}')
assert(t2.str == "hello", "decode string failed")
assert(t2.num == 123, "decode number failed")
assert(t2.flag == true, "decode bool failed")
assert(t2.null_val == nil, "decode null failed")

-- json array
local arr = json.decode('[10,20,30]')
assert(arr[1] == 10, "array[1] failed")
assert(arr[2] == 20, "array[2] failed")
assert(arr[3] == 30, "array[3] failed")

-- json encode array
local arr2 = {100, 200, 300}
local s2 = json.encode(arr2)
assert(s2 == '[100,200,300]', "encode array failed: " .. s2)

-- json nested
local nested = json.decode('{"a":{"b":{"c":"deep"}}}')
assert(nested.a.b.c == "deep", "nested decode failed")

-- json encode nested
local t3 = {x = {y = {z = 99}}}
local s3 = json.encode(t3)
local t4 = json.decode(s3)
assert(t4.x.y.z == 99, "nested encode/decode failed")

-- empty table
local s4 = json.encode({})
assert(s4 == '{}', "empty object failed: " .. s4)

-- empty array
local s5 = json.encode({1, 2})
assert(s5 == '[1,2]' or s5 == '[1, 2]', "array encode failed: " .. s5)

-- boolean values
local s6 = json.encode({a = true, b = false})
local t5 = json.decode(s6)
assert(t5.a == true, "bool true failed")
assert(t5.b == false, "bool false failed")

-- mix of array and object (table with both int and string keys is treated as object)
local mixed = {10, 20, x = "hello"}
local s7 = json.encode(mixed)
local t6 = json.decode(s7)
assert(t6[1] == nil, "array indices in mixed should not exist")
assert(t6.x == "hello", "string key in mixed failed")

print('OK')
