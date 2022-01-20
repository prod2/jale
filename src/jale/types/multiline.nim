# multiline.nim

import line

import strutils

type
  Multiline* = ref object
    lines: seq[Line]
    y: int

# getters/setters

proc X*(ml: Multiline): int =
  ml.lines[ml.y].X

proc MX*(ml: Multiline): int =
  ml.lines[ml.y].MX

proc Y*(ml: Multiline): int =
  ml.y

# constructor

proc newMultiline*(initEmpty: bool = true): Multiline =
  new(result)
  result.lines = @[]
  if initEmpty:
    result.lines.add(newLine())
  result.y = 0

proc copy*(ml: Multiline): Multiline =
  new(result)
  for l in ml.lines:
    result.lines.add(l.copy())
  result.y = ml.y

# methods

proc lineLen*(ml: Multiline): int =
  ml.lines[ml.y].len()

proc lineHigh*(ml: Multiline): int =
  ml.lines[ml.y].high()

proc len*(ml: Multiline): int =
  ml.lines.len()

proc high*(ml: Multiline): int =
  ml.lines.high()

# internal setter
proc sety(ml: Multiline, target: int) =
  ml.lines[target].navigateToMx(ml.lines[ml.y].MX)
  ml.y = target

# warning check before calling them if y lands in illegal territory
# these are unsafe!
proc decy(ml: Multiline) =
  ml.sety(ml.y-1)

proc incy(ml: Multiline) =
  ml.sety(ml.y+1)

# publically callable movement methods
proc left*(ml: Multiline) =
  ml.lines[ml.y].left()

proc right*(ml: Multiline) =
  ml.lines[ml.y].right()

proc up*(ml: Multiline) =
  if ml.y > 0:
    ml.decy

proc down*(ml: Multiline) =
  if ml.y < ml.lines.high():
    ml.incy

proc home*(ml: Multiline) =
  ml.lines[ml.y].home()

proc `end`*(ml: Multiline) =
  ml.lines[ml.y].`end`()

proc vhome*(ml: Multiline) =
  ml.sety(0)

proc vend*(ml: Multiline) =
  ml.sety(ml.high())

proc insert*(ml: Multiline, str: string) =
  ml.lines[ml.y].insert(str)

proc delete*(ml: Multiline) =
  if ml.lines[ml.y].X < ml.lineLen():
    ml.lines[ml.y].delete()
  else:
    discard # TODO merge two lines

proc backspace*(ml: Multiline) =
  if ml.lines[ml.y].X > 0:
    ml.lines[ml.y].backspace()
  else:
    discard # TODO merge two lines

proc insertline*(ml: Multiline) =
  # the default behaviour of command mode o
  if ml.y == ml.lines.high():
    ml.lines.add(newLine())
  else:
    ml.lines.insert(newLine(), ml.y + 1)
  inc ml.y # this automatically moves x and mx to 0, since the newLine creates one with these coords

proc enter*(ml: Multiline) = # TODO REDO THIS
  # the default behaviour of enter in normie editors
  if ml.lines[ml.y].X > ml.lineHigh():
    ml.insertline() # when end of line, it's just an insertline
  else:
    let cut = ml.lines[ml.y].range(ml.x, ml.lineHigh())
    ml.lines[ml.y].delete(ml.x, ml.lineHigh())
    ml.insertline()
    ml.lines[ml.y].insert(cut, 0)

proc clearline*(ml: Multiline) =
  ml.lines[ml.y].clearLine()

proc removeline*(ml: Multiline) =
  ml.lines.delete(ml.y)
  if ml.lines.len() == 0:
    ml.lines.add(newLine())
  if ml.y > ml.lines.high():
    dec ml.y #TODO: preserve x

proc getLine*(ml: Multiline, line: int = -1): string =
  if line == -1:
    ml.lines[ml.y].content
  else:
    if line >= 0 and line <= ml.lines.high():
      ml.lines[line].content
    else:
      ""

# without the extra args these work together to convert a multiline to a single
# line string. With extra args customizable
proc serialize*(ml: Multiline, sep: string = r"\n", replaceBS: bool = true): string =
  # replaceBS = replace backslash
  for line in ml.lines:
    if replaceBS:
      result &= line.content.replace(r"\", r"\\") & sep
    else:
      result &= line.content & sep
  result[0..result.high() - sep.len()]

proc deserialize*(str: string, sep: string = r"\n", replaceBS: bool = true): Multiline =
  result = newMultiline(initEmpty = false)
  for line in str.split(sep):
    if replaceBS:
      result.lines.add(newLine(line.replace(r"\\", r"\")))
    else:
      result.lines.add(newLine(line))

  result.y = result.high()
  result.x = result.lineLen()

proc fromString*(str: string): Multiline =
  # simple load of string to multiline
  deserialize(str, sep = "\n", replaceBS = false)

proc getContent*(ml: Multiline): string =
  # simple convert of multiline to string
  ml.serialize(sep = "\n", replaceBS = false)


