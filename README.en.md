# GopherLua — Lua 5.1~5.5 VM + Built-in JSON/HTTP + GLM AI + Agent

[![Go](https://github.com/package-register/glua/actions/workflows/test.yaml/badge.svg)](https://github.com/package-register/glua/actions/workflows/test.yaml)

GopherLua is a Lua VM and compiler written in pure Go. This fork extends it with **Lua 5.2~5.5 syntax**, **built-in json/http libraries**, **GLM AI integration**, and a **minimal Agent Loop**.

Original repo: [github.com/package-register/glua](https://github.com/package-register/glua)

---

## Feature Overview

### Lua Syntax Extensions

| Version | Features |
|---------|----------|
| 5.2 | `goto` / `::label::` |
| 5.3 | `//` `<<` `>>` `&` `\|` `~`, `0b` binary, hex float `0x.1p+4`, `\xHH` `\u{HHHH}`, numeric underscores `1_000_000` |
| 5.4 | `<const>` locals, `<close>` with `__close`, `__pairs`/`__ipairs` metamethods |
| 5.5 | `global` keyword, `global <const> *` strict mode |

### Built-in Libraries (Go, zero dependencies)

| Library | Usage |
|---------|-------|
| `json` | `json.encode(val)` / `json.decode(str)` |
| `http` | `http.get(url)` / `http.post(url, body, headers)` / `http.stream(method, url, body, headers, callback)` — SSE streaming supported |

### Lua Modules (pure Lua, loaded via require)

| Module | Usage |
|--------|-------|
| `glm` | `glm.ask("hello")` — GLM AI chat (streaming/non-streaming) |
| `agent` | `agent.run("task description")` — 9 atomic tools + Agent Loop |

---

## Quick Start

```bash
# Build
cd /root/coding/go-demos/gopher-lua
go build -o glua cmd/glua/glua.go

# Demo (no API key required)
./glua demo.lua

# Interactive REPL
./glua

# Run tests
go test ./... -count=1
```

### GLM AI + Agent (requires API key)

```bash
export GLM_API_KEY="your-key"
# WSL users may need a proxy:
export HTTPS_PROXY="http://172.19.96.1:7897"

# Environment check
./glua agent/setup.lua

# Run Agent
./glua agent/demo.lua
```

---

## Project Structure

```
.
├── glm.lua                # GLM AI API wrapper (pure Lua)
├── agent/                 # Agent Loop framework
│   ├── init.lua           #   Core loop
│   ├── tools.lua          #   9 atomic tools
│   ├── glm.lua            #   GLM wrapper
│   ├── config.lua         #   Configuration
│   ├── setup.lua          #   Environment check
│   └── demo.lua           #   Demo script
├── jsonlib.go             # json library (Go)
├── httplib.go             # http library (Go, with SSE stream)
├── linit.go               # Library registration
├── demo.lua               # One-click demo
├── _lua5.5-tests/         # Extension tests (12 files)
├── .skcode/memory/        # Skill memory layer
└── ...                    # Upstream gopher-lua core files
```

---

## Build the glua interpreter

```bash
go build -o glua cmd/glua/glua.go
./glua                    # Interactive REPL
./glua script.lua         # Run a script
```

---

## Known Limitations

- **`table.unpack` corrupts function references**: Agent uses indexed argument passing
- **`pcall` error loss**: gopher-lua's pcall error objects become nil when passed through nested calls
- **REPL `local` scoping**: Each REPL line is an independent chunk. Use global `glm = require "glm"`

---

## Testing

```bash
go test ./... -count=1              # All tests
go test -run TestLua55 -v           # Extension tests
go test -run TestLua -v             # Lua 5.1 compatibility
go test -run TestGlua -v            # Upstream gopher-lua tests
```

---

## Credits

- [Yusuke Inuzuka](https://github.com/yuin) — Original gopher-lua
- [GenericAgent](https://github.com/lsdefine/GenericAgent) — Agent Loop design inspiration

## License

MIT
