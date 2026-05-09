print('testing __pairs and __ipairs metamethods (Lua 5.4)')

-- normal pairs still works
do
  local t = {a = 1, b = 2, c = 3}
  local count = 0
  for k, v in pairs(t) do
    count = count + 1
    assert(v ~= nil, "pairs normal value nil")
  end
  assert(count == 3, "pairs normal count failed")
end

-- normal ipairs still works
do
  local t = {10, 20, 30}
  local sum = 0
  for i, v in ipairs(t) do
    sum = sum + v
  end
  assert(sum == 60, "ipairs normal failed")
end

-- normal pairs with nil values
do
  local t = {a = 1, b = nil, c = 3}
  local count = 0
  for k, v in pairs(t) do
    count = count + 1
  end
  assert(count == 2, "pairs with nil count failed")
end

-- normal ipairs with holes
do
  local t = {1, nil, 3}
  local count = 0
  for i, v in ipairs(t) do
    count = count + 1
  end
  assert(count == 1, "ipairs with holes failed")  -- stops at nil
end

-- __pairs basic: metamethod is called
do
  local called = false
  local t = {}
  setmetatable(t, {
    __pairs = function(self)
      called = true
      return next, self, nil
    end
  })
  for k, v in pairs(t) do end
  assert(called, "__pairs was not called")
end

-- __pairs with custom iterator (filtered keys)
do
  local t = {}
  setmetatable(t, {
    __pairs = function(self)
      local data = {a = 10, b = 20, c = 30}
      local keys = {"a", "c"}
      local i = 0
      return function(tbl, key)
        i = i + 1
        if i <= #keys then
          return keys[i], data[keys[i]]
        end
        return nil
      end, self, nil
    end
  })
  local sum = 0
  for k, v in pairs(t) do
    sum = sum + v
  end
  assert(sum == 40, "__pairs custom iterator failed")  -- only a=10, c=30
end

-- __pairs returning additional values
do
  local t = {}
  setmetatable(t, {
    __pairs = function(self)
      return function(_, key)
        if key == nil then return "hello", 42 end
        return nil
      end, self, nil
    end
  })
  local k, v = pairs(t)
  local a, b = k(v, nil)
  assert(a == "hello" and b == 42, "__pairs two values failed")
end

-- __ipairs basic: metamethod is called
do
  local called = false
  local t = {}
  setmetatable(t, {
    __ipairs = function(self)
      called = true
      local i = 0
      return function(tbl, idx)
        i = i + 1
        if i <= 3 then return i, i * 10 end
        return nil
      end, self, 0
    end
  })
  local sum = 0
  for i, v in ipairs(t) do
    sum = sum + v
  end
  assert(called, "__ipairs was not called")
  assert(sum == 60, "__ipairs sum failed")
end

-- __ipairs with custom data source
do
  local t = {}
  setmetatable(t, {
    __ipairs = function(self)
      local data = {100, 200, 300, 400}
      local i = 0
      return function(tbl, idx)
        i = i + 1
        local v = data[i]
        if v then return i, v end
        return nil
      end, self, 0
    end
  })
  local sum = 0
  for i, v in ipairs(t) do
    sum = sum + v
  end
  assert(sum == 1000, "__ipairs custom data failed")
end

-- __pairs returns non-function (falls through to default behavior)
do
  local t = {x = 1, y = 2}
  setmetatable(t, {__pairs = 42})
  local count = 0
  for k, v in pairs(t) do
    count = count + 1
  end
  assert(count == 2, "__pairs non-function fallback failed")
end

-- __ipairs returns non-function (falls through to default behavior)
do
  local t = {10, 20}
  setmetatable(t, {__ipairs = "invalid"})
  local sum = 0
  for i, v in ipairs(t) do
    sum = sum + v
  end
  assert(sum == 30, "__ipairs non-function fallback failed")
end

-- table without metatable still works normally
do
  local t = {1, 2, 3, x = 1, y = 2}
  local sum_k = 0
  local sum_v = 0
  for k, v in pairs(t) do
    sum_k = sum_k + 1
  end
  for i, v in ipairs(t) do
    sum_v = sum_v + v
  end
  assert(sum_k == 5, "pairs normal count failed")
  assert(sum_v == 6, "ipairs normal sum failed")
end

print('OK')
