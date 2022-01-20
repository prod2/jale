type
  Encoding* = enum
    ecSingle, ecUtf8
  ByteType* = enum
    btSingle, btContinuation,
    btDouble = 2, btTriple = 3, btQuadruple = 4,
#    btInvalid

proc byteType*(c: char): ByteType =
  let n = c.uint8
  if n < 0x80:
    return btSingle
  elif n < 0xc0:
    return btContinuation
  elif n >= 0xc2 and n < 0xe0:
    # c0 and c1 are invalid utf8 bytes
    return btDouble
  elif n >= 0xe0 and n < 0xf0:
    return btTriple
  elif n >= 0xf0 and n < 0xf5:
    return btQuadruple
  else:
    raise newException(Exception, "Invalid utf8 sequence")
    #return btInvalid
    

proc runeLen*(s: string): int =
  for c in s:
    case c.byteType:
      of btSingle, btDouble, btTriple, btQuadruple:
        result.inc
      of btContinuation:
        discard

