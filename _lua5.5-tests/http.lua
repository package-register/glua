print('testing http library')

-- module structure
assert(type(http) == "table", "http should be a table")
assert(type(http.get) == "function", "http.get function")
assert(type(http.post) == "function", "http.post function")
assert(type(http.put) == "function", "http.put function")
assert(type(http.delete) == "function", "http.delete function")
assert(type(http.request) == "function", "http.request function")
assert(type(http.stream) == "function", "http.stream function")

-- http.get with malformed URL (should fail fast)
local ok1, err1 = pcall(http.get, "")
assert(not ok1, "empty url should fail")

-- http.get with invalid URL format
local ok2, err2 = pcall(http.get, "not-a-valid-url!")
assert(not ok2, "invalid url should fail")

-- http.request with invalid method/url
local ok3, err3 = pcall(http.request, "INVALID", "http://invalid.")
assert(not ok3, "invalid request should fail")

-- http.post to closed port (connection refused fails fast)
local ok4, err4 = pcall(http.post, "http://127.0.0.1:9", "test_body")
assert(not ok4, "post to closed port should fail")

-- http.put with headers to closed port
local ok5, err5 = pcall(http.put, "http://127.0.0.1:9", "data", {["Content-Type"] = "text/plain"})
assert(not ok5, "put with headers should not crash")

-- http.delete
local ok6, err6 = pcall(http.delete, "http://127.0.0.1:9")
assert(not ok6, "delete to closed port should fail")

-- http.get with headers table
local ok7, err7 = pcall(http.get, "http://127.0.0.1:9", {["Accept"] = "application/json"})
assert(not ok7, "get with headers should not crash")

-- http.request with all parameters
local ok8, err8 = pcall(http.request, "GET", "http://127.0.0.1:9", "", {})
assert(not ok8, "request with all params should not crash")

-- http.stream: errors go to callback, not exception
local stream_err = nil
http.stream("GET", "not-a-url!", "", {}, function(err, data)
  stream_err = err
end)
assert(stream_err ~= nil, "stream invalid url should callback with error")

-- http.stream to closed port: callback receives error
local closed_err = nil
http.stream("GET", "http://127.0.0.1:9", "", {}, function(err, data)
  closed_err = err
end)
assert(closed_err ~= nil, "stream closed port should callback with error")

-- http.stream with callback returning "stop" (should not crash)
local stop_called = false
http.stream("GET", "http://127.0.0.1:9", "", {}, function(err, data)
  if stop_called then return "stop" end
  stop_called = true
  return "stop"
end)

print('OK')
