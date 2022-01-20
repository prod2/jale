# defaults.nim

# creates a LineEditor and binds a terminal renderer and many default keys

import editor
import keycodes
import types/multiline
import types/event
import tables
import renderer
import editor_history

proc defaultBindings*(le: LineEditor, enterSubmits = true, ctrlForVerticalMove = true) =

  le.evtTable.subscribe(jeKeypress):
    let key = args[0].intVal

    template bindKey(k: int, body: untyped) =
      if key == k:
        body

    template bindKey(k: string, body: untyped) =
      if key == keysByName[k]:
        body

    if key > 31 and key < 127:
      let ch = char(key)
      le.content.insert($ch)

    bindKey("ctrl+c"):
      le.quit()
      
    bindKey("ctrl+d"):
      if le.content.getContent() == "":
        le.quit()

    bindKey("left"):
      le.content.left()
    bindKey("right"):
      le.content.right()
    if ctrlForVerticalMove:
      bindKey("ctrlup"):
        le.content.up()
      bindKey("ctrldown"):
        if le.content.Y() == le.content.high():
          le.content.insertline()
        le.content.down()
    else:
      bindKey("up"):
        le.content.up()
      bindKey("down"):
        le.content.down()
    bindKey("pageup"):
      le.content.vhome()
    bindKey("pagedown"):
      le.content.vend()
    bindKey("home"):
      le.content.home()
    bindKey("end"):
      le.content.`end`()
    bindKey("backspace"):
      le.content.backspace()
    bindKey("delete"):
      le.content.delete()
    if enterSubmits:
      bindKey("enter"):
        le.finish()
    else:
      bindKey("enter"):
        le.content.enter()

proc newSimpleLineEditor*: LineEditor =
  result = newLineEditor()
  result.defaultBindings()
  result.bindRenderer()

proc newMultilineEditor*: LineEditor =
  result = newLineEditor()
  result.defaultBindings(false, false)
  result.bindRenderer()

proc newHistoryEditor*: LineEditor =
  result = newSimpleLineEditor()
  result.bindHistory()
