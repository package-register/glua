print('testing goto and labels (Lua 5.2)')

-- basic goto
do
  local x = 1
  goto skip
  x = 2
  ::skip::
  assert(x == 1, "basic goto failed")
end

-- goto forward
do
  local sum = 0
  local i = 1
  ::loop::
  sum = sum + i
  i = i + 1
  if i <= 5 then goto loop end
  assert(sum == 15, "goto forward failed")
end

-- goto out of block
do
  local skipped = false
  do
    goto found_label
  end
  skipped = true
  ::found_label::
  assert(not skipped, "goto out of block failed - should have skipped")
end

-- goto with multiple labels
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

-- goto inside if
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

-- goto cannot jump into a block
local ok, err = loadstring("goto inner; do ::inner:: end")
assert(not ok, "goto into block should fail")
assert(err ~= nil, "goto into block should have error message")

print('OK')
