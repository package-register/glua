print('testing operators (Lua 5.3-5.4)')

-- integer division // (floor division, Lua semantics)
assert(10 // 3 == 3, "// basic failed")
assert(-10 // 3 == -4, "// negative failed")
assert(10 // -3 == -4, "// negative divisor failed")
assert(-10 // -3 == 3, "// both negative failed")
assert(0 // 5 == 0, "// zero failed")
assert(5 // 1 == 5, "// identity failed")

-- left shift <<
assert(1 << 0 == 1, "<< 0 failed")
assert(1 << 1 == 2, "<< 1 failed")
assert(1 << 10 == 1024, "<< 10 failed")
assert(8 << 2 == 32, "<< general failed")
assert(0 << 5 == 0, "<< zero failed")

-- right shift >>
assert(1024 >> 10 == 1, ">> basic failed")
assert(32 >> 2 == 8, ">> general failed")
assert(1024 >> 0 == 1024, ">> zero failed")
assert(0 >> 5 == 0, ">> zero value failed")

-- bitwise AND &
assert(0xF0 & 0x0F == 0, "& basic failed")
assert(0xFF & 0xFF == 0xFF, "& identity failed")
assert(0x00 & 0xFF == 0x00, "& zero failed")
assert(0x0F & 0x0F == 0x0F, "& mask failed")
assert(5 & 3 == 1, "& example: 5&3=1")

-- bitwise OR |
assert(0xF0 | 0x0F == 0xFF, "| basic failed")
assert(0x00 | 0xFF == 0xFF, "| zero failed")
assert(0xFF | 0x00 == 0xFF, "| identity failed")
assert(5 | 3 == 7, "| example: 5|3=7")

-- bitwise XOR ~
assert(0xFF ~ 0x0F == 0xF0, "~ basic failed")
assert(0xFF ~ 0xFF == 0x00, "~ self failed")
assert(0x00 ~ 0xFF == 0xFF, "~ zero failed")
assert(5 ~ 3 == 6, "~ example: 5~3=6")

-- operator precedence
-- << >> have higher precedence than &
assert(1 & 3 << 1 == 0, "prec: >> before &")
-- | has lower precedence than &
assert(1 | 2 & 4 == 1, "prec: | after &")
-- ~ has precedence between | and &
assert(1 | 2 ~ 4 & 8 == 1 | (2 ~ (4 & 8)), "prec: ~ between | and &")
-- // same level as * /
assert(10 * 2 // 3 == 6, "prec: * and // left to right")
assert(10 // 2 * 3 == 15, "prec: // and * left to right")

-- combined bitwise operations
assert(0xFF & 0xF0 | 0x0F == 0xFF, "combined &| failed")
assert(0xFF ~ 0xF0 & 0x0F == 0xFF, "combined ~& failed")

-- unary ~ bitwise NOT
assert(~0 == -1, "~ 0 failed")
assert(~1 == -2, "~ 1 failed")
assert(~255 == -256, "~ 255 failed")
assert(~~42 == 42, "~~ identity failed")

-- metamethods for bitwise operators
do
  local mt = {
    __band = function(a, b) return 42 end,
    __bor  = function(a, b) return 43 end,
    __bxor = function(a, b) return 44 end,
    __bnot = function(a)    return 45 end,
    __shl  = function(a, b) return 46 end,
    __shr  = function(a, b) return 47 end,
  }
  local t = {}
  setmetatable(t, mt)
  assert(t & t == 42, "__band failed")
  assert(t | t == 43, "__bor failed")
  assert(t ~ t == 44, "__bxor failed")
  assert(t << t == 46, "__shl failed")
  assert(t >> t == 47, "__shr failed")
end

print('OK')
