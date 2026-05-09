print('testing global keyword (Lua 5.5)')

-- basic global declaration with value
global x = 42
assert(x == 42, "global basic failed")

-- global without value (defaults to nil)
global y
assert(y == nil, "global nil failed")

-- multiple globals
global a, b = 1, 2
assert(a == 1 and b == 2, "global multiple failed")

-- global function
global function add(a, b) return a + b end
assert(add(3, 4) == 7, "global function failed")

-- global with table
global t = {hello = "world"}
assert(t.hello == "world", "global table failed")

-- global can be reassigned
x = 100
assert(x == 100, "global reassign failed")

-- old-style global assignment still works (without 'global' keyword)
z = 999
assert(z == 999, "traditional global assign failed")

-- global <const> * strict mode tests
do
  -- strict mode prevents assignment to undeclared globals
  local ok1, err1 = loadstring([[
    global <const> *
    undeclared_var = 123
  ]])
  assert(not ok1, "strict mode should prevent undeclared global assignment")
end

-- strict mode with declared globals
local ok2, err2 = loadstring([[
  global <const> *
  global declared1 = 10
  global declared2 = 20
  declared1 = 100
  declared2 = 200
  assert(declared1 == 100 and declared2 == 200, "strict mode declared globals should be modifiable")
]])
assert(ok2, "strict mode with declared should compile: " .. tostring(err2))

-- global <const> * compiles
local ok3, err3 = loadstring([[
  global <const> *
  global ok_var = 1
  return ok_var
]])
assert(ok3, "global <const> * should compile: " .. tostring(err3))

-- global with complex expressions
global result = (1 + 2) * 3
assert(result == 9, "global complex expr failed")

print('OK')
