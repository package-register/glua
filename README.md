# GopherLua — Lua 5.1~5.5 VM + 内置 JSON/HTTP + GLM AI + Agent

[![Go](https://github.com/package-register/glua/actions/workflows/test.yml/badge.svg)](https://github.com/package-register/glua/actions/workflows/test.yml)

GopherLua 是纯 Go 实现的 Lua VM 和编译器。本项目在原版基础上扩展了 **Lua 5.2~5.5 语法**、**内置 json/http 库**、**GLM AI 集成**、**最小 Agent Loop**。

原版仓库: [github.com/package-register/glua](https://github.com/package-register/glua)

---

## 扩展能力一览

### Lua 语法扩展

| 版本 | 特性 |
|------|------|
| 5.2 | `goto` / `::label::` |
| 5.3 | `//` `<<` `>>` `&` `\|` `~`, `0b` 二进制, hex float `0x.1p+4`, `\xHH` `\u{HHHH}`, 数字下划线 `1_000_000` |
| 5.4 | `<const>` 常量, `<close>` 自动关闭, `__pairs`/`__ipairs` 元方法 |
| 5.5 | `global` 关键字, `global <const> *` 严格模式 |

### 内置库（Go 实现，零依赖）

| 库 | 用法 |
|----|------|
| `json` | `json.encode(val)` / `json.decode(str)` |
| `http` | `http.get(url)` / `http.post(url, body, headers)` / `http.stream(method, url, body, headers, callback)` — 支持 SSE 流式 |

### Lua 模块（纯 Lua，require 加载）

| 模块 | 用法 |
|------|------|
| `glm` | `glm.ask("你好")` — GLM AI 对话（流式/非流式） |
| `agent` | `agent.run("任务描述")` — 9 原子工具 + Agent Loop |

---

## 快速开始

```bash
# 编译
cd /root/coding/go-demos/gopher-lua
go build -o glua cmd/glua/glua.go

# 演示（不需要 API Key）
./glua ../lua/demo.lua

# 交互式 REPL
./glua

# 运行测试
go test ./... -count=1
```

### GLM AI + Agent（需 API Key）

```bash
export GLM_API_KEY="your-key"
# WSL 用户可能需要代理:
export HTTPS_PROXY="http://172.19.96.1:7897"

# 环境检查
./glua ../lua/agent/setup.lua

# 运行 Agent
./glua ../lua/agent/demo.lua
```

---

## 项目结构

```
.
├── lua/                 # Lua 模块（独立目录，不混入 Go 源码）
│   ├── glm.lua          #   GLM AI API 封装
│   ├── agent/           #   Agent Loop 框架
│   │   ├── init.lua     #     核心循环
│   │   ├── tools.lua    #     9 原子工具
│   │   └── ...
│   └── demo.lua         #   一键演示脚本
├── jsonlib.go             # json 库（Go）
├── httplib.go             # http 库（Go，含 SSE stream）
├── linit.go               # 库注册
├── demo.lua               # 一键演示脚本
├── _lua5.5-tests/         # 扩展功能测试（12 个文件）
├── .skcode/memory/        # 技能记忆层
└── ...                    # 其余 gopher-lua 核心文件
```

---

## 构建 glua 解释器

```bash
go build -o glua cmd/glua/glua.go
./glua                    # 交互式 REPL
./glua script.lua         # 运行脚本
```

---

## 已知限制

- **`table.unpack` 破坏函数引用**：Agent 工具调用改用索引传参规避
- **`pcall` 错误丢失**：gopher-lua 的 `pcall` 错误对象在嵌套传参时变 nil
- **REPL 的 `local` 不跨行**：每行独立 chunk，用全局变量 `glm = require "glm"`

---

## 测试

```bash
go test ./... -count=1              # 全部测试
go test -run TestLua55 -v           # 扩展功能测试
go test -run TestLua -v             # Lua 5.1 兼容性
go test -run TestGlua -v            # gopher-lua 原有测试
```

---

## 致谢

- [Yusuke Inuzuka](https://github.com/yuin) — 原版 gopher-lua
- [GenericAgent](https://github.com/lsdefine/GenericAgent) — Agent Loop 设计启发

## License

MIT
