import struct
import sys

data = open(sys.argv[1], "rb").read()
assert data[:4] == b"FCBM", data[:4]
version = struct.unpack(">I", data[4:8])[0]
function_count = struct.unpack(">H", data[8:10])[0]
assert version == 3, version
assert function_count == 184, function_count
assert b"\x50" in data, data
assert b"\x40" in data, data
assert b"\x41" in data, data
assert b"\x42" in data, data
assert b"\x43" in data, data
assert b"\x45" in data, data
assert b"\x55" in data, data
assert b"\x54" in data, data
assert b"\x60" in data, data
assert b"\x61" in data, data
assert b"\x62" in data, data
assert b"\x63" in data, data
assert b"\x64" in data, data
assert b"\x51" in data, data
assert b"\x03" in data, data
assert b"\x04" in data, data
assert b"\x31" in data, data
assert b"\x30" in data, data
assert b"enabled" in data, data
assert b"prefix" in data, data
print("kernel binary compile-from-plan drill passed")
