print('testing goto and labels (Lua 5.2)')

-- basic goto: skip code
do
  local x = 1
  goto skip
  x = 2
  ::skip::
  assert(x == 1, "basic goto failed")
end

-- goto forward: loop with goto
do
  local sum = 0
  local i = 1
  ::loop::
  sum = sum + i
  i = i + 1
  if i <= 5 then goto loop end
  assert(sum == 15, "goto forward loop failed")
end

-- goto out of nested block
do
  local skipped = false
  do
    goto found_label
  end
  skipped = true
  ::found_label::
  assert(not skipped, "goto out of block failed")
end

-- goto with multiple labels and targets
do
  local x = 0
  goto label2
  ::label1::
  x = 1
  goto done
  ::label2::
  x = 2
  goto done
  ::done::
  assert(x == 2, "goto multiple labels failed")
end

-- goto inside if branches
do
  local x = 0
  if true then
    goto yes
  else
    ::yes::
    x = 1
  end
  ::yes::
  x = 2
  assert(x == 2, "goto inside if failed")
end

-- goto in else branch
do
  local x = 0
  if false then
    x = 100
  else
    goto else_label
  end
  ::else_label::
  assert(x == 0, "goto in else failed")
end

-- goto backward (loop via goto only)
do
  local i = 3
  local result = 0
  ::top::
  result = result + i
  i = i - 1
  if i >= 1 then goto top end
  assert(result == 6, "goto backward loop failed")  -- 3+2+1
end

local ok1, err1 = loadstring("goto inner; do ::inner:: end")
assert(not ok1, "goto into block should fail")
assert(err1 ~= nil, "goto into block should have error message")

-- goto to label defined later in same block
do
  local x = 0
  goto later
  ::later::
  x = 42
  assert(x == 42, "goto forward label failed")
end

-- duplicate label (compile error)
local ok2, err2 = loadstring("::x:: ::x::")
assert(not ok2, "duplicate label should fail")

print('OK')
