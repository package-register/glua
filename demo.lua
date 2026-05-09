-- demo.lua — gopher-lua 能力演示
-- 运行: ./glua demo.lua (从项目根目录)

print("========================================")
print("  gopher-lua 扩展能力演示")
print("========================================")
print()

-- 1. Lua 5.3+ 运算符
print("--- 运算符 ---")
print("10 // 3 =", 10 // 3)
print("1 << 10 =", 1 << 10)
print("0xFF & 0x0F =", 0xFF & 0x0F)
print("0xF0 | 0x0F =", 0xF0 | 0x0F)
print("0xFF ~ 0x0F =", 0xFF ~ 0x0F)
print()

-- 2. 新字面量
print("--- 字面量 ---")
print("0b1010 =", 0b1010)
print("0x.1p+4 =", 0x.1p+4)
print("1_000_000 =", 1_000_000)
print()

-- 3. global 关键字
print("--- global 关键字 ---")
global x = 42
print("global x =", x)
global function add(a, b) return a + b end
print("add(3, 4) =", add(3, 4))
print()

-- 4. json 库
print("--- json 库 ---")
local t = json.decode('{"hello": "world", "nums": [1,2,3]}')
print("hello =", t.hello)
print("nums[2] =", t.nums[2])
local s = json.encode({a = 1, b = true, c = {nested = true}})
print("encode =", s)
print()

-- 5. <const> 和 <close>
print("--- 属性 ---")
local x <const> = 100
print("const x =", x)

local obj = {name = "resource"}
setmetatable(obj, {__close = function(self) print("closing:", self.name) end})
do
  local r <close> = obj
  print("inside block")
end
print("after block (close was called above)")
print()

-- 6. goto
print("--- goto ---")
local i = 1
local sum = 0
::loop::
sum = sum + i
i = i + 1
if i <= 5 then goto loop end
print("sum 1..5 =", sum)
print()

-- 7. __pairs / __ipairs
print("--- __pairs ---")
local special = {}
setmetatable(special, {
  __pairs = function(t)
    return function(_, key)
      if key == nil then return "custom", 42 end
      return nil
    end, t, nil
  end
})
for k, v in pairs(special) do
  print("  pairs:", k, v)
end
print()

-- 8. http 模块 (不实际发请求，只验证加载)
print("--- http 模块 ---")
print("http.get =", type(http.get))
print("http.stream =", type(http.stream))
print()

-- 9. GLM 模块 (需要 API Key)
print("--- glm 模块 ---")
local glm = require("glm")
glm.load_key_from_env("GLM_API_KEY")
local ok = glm.set_key ~= nil
print("glm 模块已加载:", ok)
print()

print("========================================")
print("  演示完成!")
print("========================================")
