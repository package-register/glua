print('testing <const> attribute (Lua 5.4)')

-- basic const declaration
do
  local x <const> = 42
  assert(x == 42, "const basic failed")
end

-- const with arithmetic expressions
do
  local x <const> = 10 + 20 * 3
  assert(x == 70, "const expression failed")
end

-- const with strings
do
  local s <const> = "hello world"
  assert(s == "hello world", "const string failed")
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

-- const with mixed expressions
do
  local a <const> = 100
  local b <const> = a + 50
  assert(b == 150, "const derived failed")
end

-- const with table constructor (table content is modifiable)
do
  local t <const> = {a = 1, b = 2}
  assert(t.a == 1, "const table failed")
  t.a = 10
  assert(t.a == 10, "const table content modify failed")
end

-- const with function result
do
  local function f() return 100 end
  local x <const> = f()
  assert(x == 100, "const function result failed")
end

-- const can be read in expressions
do
  local x <const> = 5
  local y = x * 2
  assert(y == 10, "const read only failed")
end

-- const cannot be reassigned (compile error)
local ok1, err1 = loadstring("local x <const> = 10; x = 20")
assert(not ok1, "const reassign should fail at compile time")

-- const cannot be modified via expression
local ok2, err2 = loadstring("local x <const> = 10; x = x + 1")
assert(not ok2, "const modify should fail at compile time")

-- const with nil cannot be reassigned
local ok3, err3 = loadstring("local x <const> = nil; x = 1")
assert(not ok3, "const nil reassign should fail")

-- const + mutable variable combo
do
  local a <const> = 1
  local b = 2
  b = 3
  assert(a == 1 and b == 3, "const + mutable combo failed")
end

-- const shadowing in nested block
do
  local x <const> = 10
  do
    local x <const> = 20
    assert(x == 20, "const shadow inner failed")
  end
  assert(x == 10, "const outer after shadow failed")
end

-- const with single-line function assignment
do
  local function make(n) return n * 2 end
  local x <const> = make(21)
  assert(x == 42, "const make function failed")
end

print('OK')
