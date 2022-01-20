import jale/editor
import jale/types/event
import jale/defaults

import strutils

var keep = true

let e = newHistoryEditor()

e.evtTable.subscribe(jeQuit):
  keep = false

e.prompt = "> "

while keep:
  let input = e.read()
  echo "output:<" & input.replace("\n", "\\n") & ">"

