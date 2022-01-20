import types/history
import editor
import types/event
import keycodes
import tables

import options

proc bindHistory*(le: LineEditor, useControl: bool = false) =
  # adds hooks to events
  # after reading finished, it adds to history
  # before reading, it adds the temporary input to the history
  let hist = newHistory()

  le.evtTable.subscribe(jeFinish):
    hist.clean()
    hist.newEntry(le.content)

  le.evtTable.subscribe(jePreRead):
    hist.newEntry(le.content, temp = true)
    discard hist.toEnd()

  # Adds history keybindings to editor (up, down, pg up/down)
  # Works with the history provided
  # if useShift is true, then the up/down keys and page up/down
  # will remain free, and shift+up/down and ctrl+pg up/down
  # will be used

  # for sanity, NEVER bind both history and multiline to control
  
  let upkey = keysByName[if useControl: "controlup" else: "up"]
  let downkey = keysByName[if useControl: "controldown" else: "down"]
  let homekey = keysByName[if useControl: "ctrlpageup" else: "pageup"]
  let endkey = keysByName[if useControl: "ctrlpagedown" else: "pagedown"]

  le.evtTable.subscribe(jeKeypress):
    let key = args[0].intVal
    if key == upkey:
      let res = hist.delta(-1)
      if res.isSome():
        le.content = res.get()
        le.redraw()
    elif key == downkey:
      let res = hist.delta(1)
      if res.isSome():
        le.content = res.get()
        le.redraw()
    elif key == homekey:
      let res = hist.toStart()
      if res.isSome():
        le.content = res.get()
        le.redraw()
    elif key == endkey:
      let res = hist.toStart()
      if res.isSome():
        le.content = res.get()
        le.redraw()
    else:
      discard
