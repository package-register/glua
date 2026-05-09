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

-- traditional global assignment still works
z = 999
assert(z == 999, "traditional global assign failed")

-- global in function scope
function test_global_in_fn()
  global fn_var = 42
  return fn_var
end
assert(test_global_in_fn() == 42, "global inside fn failed")
assert(fn_var == 42, "global inside fn visible outside failed")

-- global <const> * strict mode tests
-- strict mode prevents assignment to undeclared globals
local ok1, err1 = loadstring([[
  global <const> *
  undeclared_var = 123
]])
assert(not ok1, "strict mode should prevent undeclared global assignment")

-- strict mode with declared globals (should work)
local ok2, err2 = loadstring([[
  global <const> *
  global declared1 = 10
  global declared2 = 20
  declared1 = 100
  declared2 = 200
  assert(declared1 == 100 and declared2 == 200, "strict mode declared assign failed")
]])
assert(ok2, "strict mode with declared should compile: " .. tostring(err2))

-- strict mode with global function declared
local ok3, err3 = loadstring([[
  global <const> *
  global function test_fn(a, b) return a + b end
  return test_fn(3, 4)
]])
assert(ok3, "strict mode with global fn: " .. tostring(err3))
local fn = assert(loadstring([[
  global <const> *
  global function test_fn(a, b) return a + b end
  return test_fn
]]))
assert(fn ~= nil)

-- global with complex expression
global result = (1 + 2) * 3
assert(result == 9, "global complex expr failed")

-- global multiple with mixed values
global u, v, w = 10, "hello", true
assert(u == 10 and v == "hello" and w == true, "global mixed types failed")

print('OK')
