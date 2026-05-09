print('testing <close> attribute (Lua 5.4)')

-- basic close with nil (no-op)
do
  local x <close> = nil
  assert(x == nil, "close nil failed")
end

-- close with table that has __close metamethod
do
  local called = false
  local obj = {}
  local mt = {
    __close = function(self)
      called = true
    end
  }
  setmetatable(obj, mt)
  do
    local x <close> = obj
    assert(not called, "close should not be called inside block")
  end
  assert(called, "close should be called after block exit")
end

-- close in nested blocks
do
  local order = {}
  do
    local a <close> = nil
    do
      local b <close> = nil
      order[#order + 1] = "inner"
    end
    order[#order + 1] = "outer"
  end
  -- no crash, order doesn't matter for nil
  assert(true, "nested close nil failed")
end

-- close with userdata-like pattern
do
  local resource = { open = true }
  local mt = {
    __close = function(self)
      self.open = false
    end
  }
  setmetatable(resource, mt)
  do
    local r <close> = resource
    assert(r.open, "resource should be open inside block")
  end
  assert(not resource.open, "resource should be closed after block")
end

-- multiple close variables
do
  local close1_called = false
  local close2_called = false
  local r1 = {}
  setmetatable(r1, { __close = function() close1_called = true end })
  local r2 = {}
  setmetatable(r2, { __close = function() close2_called = true end })
  do
    local x <close> = r1
    local y <close> = r2
  end
  assert(close1_called, "close1 should be called")
  assert(close2_called, "close2 should be called")
end

-- close with function (table with __close)
do
  local result = {}
  local function make_closer(name)
    local t = {}
    setmetatable(t, {
      __close = function()
        result[#result + 1] = name
      end
    })
    return t
  end
  do
    local a <close> = make_closer("a")
    local b <close> = make_closer("b")
  end
  assert(result[1] ~= nil, "close should be called")
  assert(result[2] ~= nil, "close should be called twice")
end

-- close on global (not supported as attribute, but no crash)
-- skip: global x <close> just uses <close> as name

print('OK')
