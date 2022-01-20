import jale/editor
import jale/types/multiline
import jale/defaults
import jale/types/event
import jale/keycodes
import tables

import terminal
import strutils
import os

eraseScreen()
setCursorPos(stdout, 0,0)

let e = newMultilineEditor()

if paramCount() > 0:
  let arg = paramStr(1)
  if fileExists(arg):
    e.content = readFile(arg).fromString()

var save = false
e.evtTable.subscribe(jeKeypress):
  if args[0].intVal == keysByName["ctrl+s"]:
    e.finish()
    save = true


e.horizontalScrollMode = hsbAllScroll
let result = e.read()
if save and paramCount() > 0:
  writeFile(paramStr(1), result)

