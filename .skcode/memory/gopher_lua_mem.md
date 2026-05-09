# gopher-lua 扩展技能

> 技能晶体化自：Lua 5.2-5.5 语法扩展 + SSE 流式 HTTP + GLM API 封装  
> 核心理念：不预载技能——从执行中晶体化（GenericAgent 思想）

## 记忆层级

```
L0(META-SOP): .skcode/memory/meta_sop.md
L1(Insight):  .skcode/memory/gopher_lua_mem.md   ← 本文
L2(Facts):    本文件（索引+技能）
L3(Skills):   独立技能文件（按需拆分）
L4(Raw):      历史会话 / git log
```

---

## 架构总览

```
Lua 代码
  │
  ├── pure Lua 模块 (glm.lua)         ← L3: 零编译，require 加载
  │     └── 调用 Go 内置库 (http + json)
  │
  ├── Go 内置库 (jsonlib/httplib)     ← L1: 静态注册，linit.go
  │     ├── OpenXxx(L) → RegisterModule
  │     └── L.CheckString/L.PCall 等 API
  │
  ├── 语法扩展 (lexer→parser→opcode→compile→vm)  ← L2: 全链路
  │
  └── 测试 (_lua5.5-tests/*.lua)      ← 验证层
```

---

## 技能 1：添加内置 Go 库

### 文件清单（按创建顺序）

| 步骤 | 文件 | 内容 |
|------|------|------|
| 1 | `xxxlib.go` (新) | 库实现：`OpenXxx` + 函数表 `var xxxFuncs` |
| 2 | `linit.go` | 添加 `XxxLibName` + 注册到 `luaLibs` |
| 3 | `_lua5.5-tests/xxx.lua` (新) | 测试脚本 |
| 4 | `script_test.go` | 添加到 `lua55Tests` |

### 代码骨架

```go
// xxxlib.go
package lua

var xxxFuncs = map[string]LGFunction{
    "func1": xxxFunc1,
}

func OpenXxx(L *LState) int {
    L.RegisterModule("xxx", xxxFuncs)
    return 1
}

func xxxFunc1(L *LState) int {
    arg := L.CheckString(1)        // 必选参数
    opt := L.OptString(2, "default") // 可选参数
    // ... 业务逻辑 ...
    L.Push(result)
    return 1
}
```

### 约束

- 函数签名固定：`func(*LState) int`，返回值是 push 到栈上的结果数量
- 错误通过 `L.RaiseError("msg: %v", err)` 抛出，Lua 侧用 `pcall` 捕获
- `RegisterModule` 自动创建同名全局表，函数注册为表的方法

---

## 技能 2：添加新语法/运算符

### 全链路（6 层）

```
词法(lexer.go) → AST(ast/expr.go) → 文法(parser.go.y) → 字节码(opcode.go) → 编译(compile.go) → VM(vm.go)
```

### 每层示例（以 `//` 整数除法为例）

| 层 | 文件 | 改动 |
|----|------|------|
| 词法 | `parse/lexer.go` | `case '/': if Peek()=='/'` → `TIDiv` |
| 文法 | `parse/parser.go.y` | `%token TIDiv` + `%left '*' '/' '%' TIDiv` + `expr TIDiv expr` 规则 |
| 文法生成 | `goyacc -o parser.go parser.go.y` | 重生成 parser |
| 字节码 | `opcode.go` | `OP_IDIV` (iota) + `opProps` + `opToString` |
| 编译 | `compile.go` | `case "//": op = OP_IDIV` |
| VM | `vm.go` | `opArith` 分发表 + `numberArith` 实现 + `objectArith` metamethod |
| 测试 | `_lua5.5-tests/operators.lua` | `assert(10 // 3 == 3)` |

### 一元运算符特例（`~` 位取反）

```
词法: '~' 不跟 '=' 时 tok.Type = ch (ASCII 126)
文法: '~' expr %prec UNARY { $$ = &ast.UnaryBnotOpExpr{Expr: $2} }
AST:  ast/expr.go 加 UnaryBnotOpExpr
字节码: OP_BNOT (无 B/C 操作数)
VM:   独立分发表条目（非 opArith），直接处理 ^int64
```

### 警告

- `_vm.go`（源文件）和 `vm.go`（go-inline 生成的）不同步时，直接编辑 `vm.go`
- `parser.go` 由 `goyacc` 从 `.y` 生成，编辑 `.y` 后需重生成
- 新 opcode 的 `jumpTable` 条目必须与 opcode 常量索引严格一致

---

## 技能 3：添加 SSE 流式功能（Go→Lua 回调）

### Go 侧模式

```go
func httpStream(L *LState) int {
    callback := L.CheckFunction(5)   // 取 Lua 函数参数
    // 错误走回调，不抛异常
    if err != nil {
        callStreamCallback(L, callback, "error msg", "")
        return 0
    }
    for scanner.Scan() {             // 流式读取
        callStreamCallback(L, callback, "", line)
    }
    return 0
}

func callStreamCallback(L *LState, cb *LFunction, err, data string) string {
    L.Push(cb)
    L.Push(LNil)  // 或 LString(err)
    L.Push(LString(data))  // 或 LNil
    L.PCall(2, 1, nil)
    ret := L.Get(1)
    if ret == LString("stop") { return "stop" }
    return ""
}
```

### Lua 侧使用

```lua
http.stream("POST", url, body, headers, function(err, data)
    if err then print("Error:", err); return end
    if data == nil then print("[DONE]"); return end
    local chunk = json.decode(data)
    -- 处理数据...
    return "stop"  -- 可手动终止流
end)
```

### 回调契约

| 场景 | `err` | `data` |
|------|-------|--------|
| 正常数据 | `nil` | JSON 字符串 |
| `[DONE]` | `nil` | `nil` |
| 错误 | 错误消息 | `nil` |
| 用户终止 | — | 回调返回 `"stop"` |

### 已知限制

- `L.PCall` 调 Lua 回调时，**pcall 捕获的 error 对象传给函数会破坏闭包变量**（gopher-lua bug）
- 规避：`glm.lua` 中用 `if api_key == ""` 直接判断，不用 `error()` + `pcall`

---

## 技能 4：纯 Lua 封装外部 API（以 GLM 为例）

### 模式

```lua
local glm = {}
local api_key = ""

function glm.set_key(key) api_key = key end

function glm.chat(messages, opts)
    if not check_key() then return nil, "key not set" end
    local body = build_body(messages, opts)
    local headers = build_headers()
    local ok, resp = pcall(http.post, API_BASE, json.encode(body), headers)
    if not ok then return nil, tostring(resp) end
    if resp.status >= 400 then return nil, "HTTP error" end
    local ok2, result = pcall(json.decode, resp.body)
    if not ok2 then return nil, "json error" end
    return result, nil
end

function glm.chat_stream(messages, on_chunk, opts)
    -- 流式：用 http.stream + json.decode 组合
    http.stream("POST", url, body, headers, function(err, data)
        if err then on_chunk(nil, err); return end
        if data == nil then on_chunk("", true); return end
        local ok, chunk = pcall(json.decode, data)
        if chunk.choices then
            on_chunk(chunk.choices[1].delta.content, false)
        end
    end)
end

return glm
```

### 设计原则

- **零编译**：纯 Lua 实现，`require` 加载，改 prompt/参数不需重编译 Go
- **错误优先**：`return result, nil` / `return nil, err` 模式
- **关键安全**：API key 不硬编码，通过环境变量或配置文件加载

---

## 技能 5：测试模式

### 测试文件结构

```lua
print('testing <feature>')
-- 断言...
assert(condition, "failure message")
print('OK')
```

### 编译期错误测试

```lua
local ok, err = loadstring("local x <const> = 1; x = 2")
assert(not ok, "reassign const should fail")
```

### 运行时错误测试

```lua
local ok, err = pcall(function()
    -- 预期会错的代码
end)
assert(not ok, "should fail")
```

### 流式回调测试

```lua
local cb_err = nil
http.stream("GET", "http://127.0.0.1:9", "", {}, function(err, data)
    cb_err = err
end)
assert(cb_err ~= nil, "should callback with error")
```

---

## 已知 Bug 与限制

| Bug | 影响 | 状态 |
|-----|------|------|
| `pcall` 错误对象破坏闭包变量 | `glm.lua` 用 `error()`+`pcall` 会丢失闭包赋值 | **规避**：用布尔返回值 |
| `constVars` 跨块泄露 | `<const>` 声明在离开块后仍生效 | ✅ 已修复 |
| `jumpTable` 分发表错位 | 新 opcode 按 iota 顺序，但分发表更新遗漏 | ✅ 已修复 |
| `_vm.go` vs `vm.go` 不同步 | 源文件缺少新 opcode，下次 go-inline 会覆盖 | ⚠️ 需要手动同步 |
| 一元 `~` 语法规则缺失 | `~x` 语法解析失败 | ✅ 已修复 |

---

## 关键文件和 git log

```
580444c ✨ feat: 扩展语法支持 Lua 5.2-5.5 核心特性
7a769e2 ✨ feat: 内置 json 编解码和 http 网络请求库
476f667 ✅ test: 全面增强测试覆盖 + 修复 constVars 跨块泄露
721a424 🐛 fix: 修复 agent 扫描发现的7个关键 Bug
e387a89 ✨ feat: SSE 流式 http.stream + GLM API 纯 Lua 封装
```

---

## 快速参考

| 要做什么 | 起点 | 参考技能 |
|----------|------|----------|
| 加新内置库 | 复制 `jsonlib.go` | 技能 1 |
| 加新运算符 | 看 `//` 的完整链路 | 技能 2 |
| 加流式 API | 看 `http.stream` | 技能 3 |
| 封装外部 API | 看 `glm.lua` | 技能 4 |
| 写测试 | 复制 `_lua5.5-tests/xxx.lua` | 技能 5 |
| 重生成 parser | `goyacc -o parser.go parser.go.y` | 技能 2 |
| 运行测试 | `go test -run TestLua55` | — |

## 技能 6：实现最小 Agent Loop

### 架构

```
agent.lua (纯 Lua, ~180行)
  ├── 9 原子工具 (read_file/write_file/list_dir/execute/search_files/grep/http_get/json_decode/json_encode)
  ├── LLM 调用 (基于 glm.chat_stream)
  ├── JSON 回复解析 (支持 ```json、纯 JSON、花括号提取)
  └── 主循环: user input → LLM(tool_call) → execute → continue → final_answer
```

### 核心循环 (~80行)

```lua
function agent.run(task, opts)
  local messages = {
    {role = "system", content = tool_descriptions},
    {role = "user", content = task},
  }
  for step = 1, max_steps do
    local response = llm_call(messages)
    local parsed = parse_json(response)

    if parsed.final_answer then return parsed.final_answer end

    if parsed.tool_call then
      local name, args = parsed.tool_call.name, parsed.tool_call.args or {}
      local result, err = execute_tool(name, args)
      messages[#messages + 1] = {role = "user", content = result_msg}
    end
  end
end
```

### 工具调用格式

```json
{"tool_call": {"name": "read_file", "args": ["path.txt"]}}
{"final_answer": "结果"}
```

### 约束
- 纯 Lua 实现，零编译依赖
- 每次只调一个工具（简化 loop）
- 结果截断 2000 字符
- 默认最多 10 步
