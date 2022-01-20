import jale/defaults
import jale/editor
import jale/renderer
import jale/types/event

import strutils

var keep = true
let e = newSimpleLineEditor()

e.evtTable.subscribe(jeQuit):
  keep = false

e.prompt = "> "
while keep:
  let input = e.read()
  echo "output:<" & input.replace("\n", "\\n") & ">"
