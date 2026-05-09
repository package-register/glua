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

-- __pairs basic
do
  local called = false
  local t = {}
  setmetatable(t, {
    __pairs = function(self)
      called = true
      return next, self, nil
    end
  })
  for k, v in pairs(t) do
    -- nothing
  end
  assert(called, "__pairs was not called")
end

-- __pairs with custom iterator
do
  local t = {}
  setmetatable(t, {
    __pairs = function(self)
      local data = {a = 10, b = 20}
      local keys = {"a", "b"}
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
  assert(sum == 30, "__pairs custom iterator failed")
end

-- __ipairs basic
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

-- __ipairs with custom data
do
  local t = {}
  setmetatable(t, {
    __ipairs = function(self)
      local data = {100, 200, 300}
      return function(tbl, i)
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
  assert(sum == 600, "__ipairs custom data failed")
end

-- __pairs returns non-function (error handling via pcall)
-- table without metatable still works normally for pairs/ipairs
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
