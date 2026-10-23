import 'dart:convert';

int stableHash(String id) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(id)) {
    hash ^= byte;
    hash = ((hash & 0xffff) * 0x01000193 + ((hash >> 16) * 0x0193 << 16)) &
        0xffffffff;
  }
  return hash;
}
