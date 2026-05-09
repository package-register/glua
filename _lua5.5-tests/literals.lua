print('testing literals (Lua 5.3-5.5)')

-- binary literals 0b
assert(0b1010 == 10, "0b basic failed")
assert(0b0 == 0, "0b zero failed")
assert(0b1 == 1, "0b one failed")
assert(0b11111111 == 255, "0b 8 bits failed")
assert(0b10101010 == 170, "0b pattern failed")

-- binary with underscores
assert(0b1010_1010 == 170, "0b underscore failed")
assert(0b1111_0000 == 240, "0b underscore 2 failed")

-- hex floats
assert(0x.1p+4 == 1.0, "hex float 0x.1p4 failed")
assert(0x.8p+0 == 0.5, "hex float 0x.8p0 failed")
assert(0x1p-1 == 0.5, "hex float 0x1p-1 failed")
assert(0x1.0p+0 == 1.0, "hex float 0x1.0p0 failed")
assert(0x0.1p0 == 0.0625, "hex float 0x0.1p0 failed")
assert(0x1p10 == 1024.0, "hex float 0x1p10 failed")

-- hex floats with underscores
assert(0x1.0p+0 == 1.0, "hex float basic worked")
assert(0xFF == 255, "hex basic worked")

-- \x hex escape in strings
assert("\x48\x65\x6C\x6C\x6F" == "Hello", "\\x basic failed")
assert("\x00\xFF\xAB" == "\0\255\171", "\\x hex values failed")
assert("\x41\x42\x43" == "ABC", "\\x uppercase failed")

-- \u unicode escape
assert("\u{4E16}\u{754C}" == "世界", "\\u basic failed")
assert("\u{1F600}" == "😀", "\\u emoji failed")
assert("\u{0}\u{7F}" == "\0\127", "\\u ASCII range failed")
assert(string.len("\u{80}") == 2, "\\u 2-byte UTF-8 len failed")
assert(string.len("\u{800}") == 3, "\\u 3-byte UTF-8 len failed")
assert(string.len("\u{10000}") == 4, "\\u 4-byte UTF-8 len failed")
assert("\u{41}" == "A", "\\u ASCII via unicode failed")

-- numeric underscores
assert(1_000_000 == 1000000, "underscore basic failed")
assert(1_000 == 1000, "underscore thousand failed")
assert(1_000_000_000 == 1000000000, "underscore billion failed")
assert(1_2_3_4_5 == 12345, "underscore multiple failed")

-- hex with underscores
assert(0xFF_FF == 65535, "hex underscore failed")
assert(0xFF_FF_FF_FF == 4294967295, "hex underscore 32bit failed")
assert(0xDE_AD_BE_EF == 3735928559, "hex underscore pattern failed")

print('OK')
