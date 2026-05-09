print('testing http library')

-- http module exists
assert(type(http) == "table", "http should be a table")
assert(type(http.get) == "function", "http.get should be a function")
assert(type(http.post) == "function", "http.post should be a function")
assert(type(http.put) == "function", "http.put should be a function")
assert(type(http.delete) == "function", "http.delete should be a function")
assert(type(http.request) == "function", "http.request should be a function")

-- http.get with invalid URL format (should fail fast)
local ok, err = pcall(http.get, "not-a-valid-url!")
assert(not ok, "http.get on invalid url should fail")

-- http.request with invalid method/url
local ok2, err2 = pcall(http.request, "INVALID", "http://invalid.")
assert(not ok2, "http.request on invalid should fail")

-- request with headers (should not crash)
local ok3, err3 = pcall(http.get, "http://192.0.2.1", {["X-Test"] = "hello"})
assert(not ok3, "should fail but shouldn't crash")

print('OK')
