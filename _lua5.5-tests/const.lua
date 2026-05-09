print('testing <const> attribute (Lua 5.4)')

-- basic const declaration
do
  local x <const> = 42
  assert(x == 42, "const basic failed")
end

-- const with expressions
do
  local x <const> = 10 + 20
  assert(x == 30, "const expression failed")
end

-- const with strings
do
  local s <const> = "hello"
  assert(s == "hello", "const string failed")
end

-- const with boolean
do
  local b <const> = true
  assert(b, "const bool failed")
end

-- const with nil
do
  local n <const> = nil
  assert(n == nil, "const nil failed")
end


-- const cannot be reassigned (compile error)
-- This test verifies the error exists by running it in a new chunk
local ok1, err1 = loadstring("local x <const> = 10; x = 20")
assert(not ok1, "const reassign should fail at compile time")

-- const can be used in expressions
do
  local x <const> = 5
  local y = x * 2
  assert(y == 10, "const in expression failed")
end

-- const with function result
do
  local function f() return 100 end
  local x <const> = f()
  assert(x == 100, "const function result failed")
end

-- const <const> on global not supported in strict mode test
-- just test that local <const> works

print('OK')
