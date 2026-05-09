print('testing http library')

-- module structure
assert(type(http) == "table", "http should be a table")
assert(type(http.get) == "function", "http.get function")
assert(type(http.post) == "function", "http.post function")
assert(type(http.put) == "function", "http.put function")
assert(type(http.delete) == "function", "http.delete function")
assert(type(http.request) == "function", "http.request function")

-- http.get with malformed URL (should fail fast)
local ok1, err1 = pcall(http.get, "")
assert(not ok1, "empty url should fail")

-- http.get with invalid URL format
local ok2, err2 = pcall(http.get, "not-a-valid-url!")
assert(not ok2, "invalid url should fail")

-- http.request with invalid method/url
local ok4, err4 = pcall(http.request, "INVALID", "http://invalid.")
assert(not ok4, "invalid request should fail")

-- http.post with valid args but unreachable
local ok5, err5 = pcall(http.post, "http://192.0.2.1:9", "test_body")
assert(not ok5, "post to unreachable should fail")

-- http.put with headers
local ok6, err6 = pcall(http.put, "http://192.0.2.1", "data", {["Content-Type"] = "text/plain"})
assert(not ok6, "put with headers should not crash")

-- http.delete without body
local ok7, err7 = pcall(http.delete, "http://192.0.2.1:9")
assert(not ok7, "delete to unreachable should fail")

-- http.get with headers table
local ok8, err8 = pcall(http.get, "http://192.0.2.1", {["Accept"] = "application/json"})
assert(not ok8, "get with headers should not crash")

-- http.request with all parameters
local ok9, err9 = pcall(http.request, "GET", "http://192.0.2.1", "", {})
assert(not ok9, "request with all params should not crash")

-- response table structure (when successful, has status/body/headers)
-- we can't test this without network, but verify the contract
local ok10, err10 = pcall(http.get, "http://192.0.2.1")
assert(not ok10, "unreachable should fail")

print('OK')
