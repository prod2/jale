# line.nim
#
# supports multiple encodings
# all public methods shall work the same regardless of encoding
#
# mx/x are volatile, they are not expected to store information long term

import strformat
import ../utf8

type
  Line* = object
    content: string
    encoding: Encoding
    length: int
    x: int # real index
    mx: int # mouse index (rune index)

# getter

proc content*(line: Line): string =
  line.content

proc X*(line: Line): int =
  # line.X == line.len when at complete end
  # line.X == line.high when at over the last char
  # line.X == 0 when over the first char
  line.mx

# constructor

proc newLine*: Line =
  Line(content: "", encoding: ecUtf8, length: 0, x: 0, mx: 0)

proc copy*(l: Line): Line =
  Line(content: l.content, encoding: l.encoding, length: l.length, x: l.x, mx: l.mx)

# methods

proc insert*(line: var Line, str: string) =
  # position: x
  case line.encoding:
    of ecUtf8:
      line.length += str.runeLen
    of ecSingle:
      line.length += str.len
  if pos > line.content.high():
    line.content &= str
  elif pos == 0:
    line.content = str & line.content
  else:
    line.content = line.content[0..pos-1] & str & line.content[pos..line.content.high()]

  # TODO: x += str.len()

proc delete(line: var Line, start: int, finish: int) =
  if start > finish or start < 0 or finish > line.content.high():
    raise newException(CatchableError, &"Invalid arguments for Line.delete: start {start}, finish {finish} for line of length {line.content.len()}")
  var result = ""
  if start > 0:
    result &= line.content[0..start-1]
  if finish < line.content.high():
    result &= line.content[finish+1..line.content.high()]
  line.content = result


proc backspace*(line: var Line) =
  # TODO: position: x, move x
  # from multiline:
  if ml.x > 0:
    ml.lines[ml.y].backspace()
  elif ml.x == 0 and ml.y > 0:
    let cut = ml.lines[ml.y].content
    ml.lines.delete(ml.y)
    dec ml.y    
    ml.x = ml.lineLen()
    ml.lines[ml.y].insert(cut, ml.x)
  # end "from multiline"
  if position == 0:
    return

proc delete*(line: var Line) =
  # TODO: position: x

proc navigateToMx*(line: var Line, target: mx) =

proc left*(line: var Line) =

proc right*(line: var Line) =

proc home*(line: var Line) =

proc `end`*(line: var Line) =
  

#proc range*(line: var Line, start: int, finish: int): string =
#  if start > finish or start < 0 or finish > line.content.high():
#    raise newException(CatchableError, &"Invalid arguments for Line.range: start {start}, finish {finish} for line of length {line.content.len()}")
#  result = line.content[start..finish]

proc len*(line: Line): int =
  line.length

proc high*(line: Line): int =
  line.length - 1

proc clearLine*(line: var Line) =
  line.content = ""
  line.length = 0
