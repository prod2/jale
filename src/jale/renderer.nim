# renderer.nim
#
# listens to LineEditor events and updates the screen

import editor
import types/event
import types/multiline
import strutils
import terminal


proc renderLine*(prompt: string, text: string, hscroll: int = 0) =
  eraseLine()
  setCursorXPos(0)
  var lower = hscroll
  var upper = hscroll + terminalWidth() - prompt.len() - 1
  if upper > text.high():
    upper = text.high()
  if lower < -1:
    raise newException(Defect, "negative hscroll submitted to renderLine")
  if lower > text.high():
    write stdout, prompt
  else:
    let content = prompt & text[lower..upper]
    write stdout, content


proc render(editor: LineEditor, line: int = -1) =
  ## Assumes that the cursor is already on the right line then
  ## proceeds to render the line-th line of the editor (if -1, will check
  ## the y).
  var y = line
  if y == -1:
    y = editor.content.Y
 
  # the prompt's length is assumed to be always padded
  let prompt = if y == 0: editor.prompt else: " ".repeat(editor.prompt.len())
  let content = editor.content.getLine(y)

  if editor.horizontalScrollMode == hsbAllScroll or 
    (editor.horizontalScrollMode == hsbSingleScroll and y == editor.content.Y):
    renderLine(prompt, content, editor.hscroll)
  else:
    renderLine(prompt, content, 0)

proc fullRender(editor: LineEditor) =
  # from the top cursor pos, it draws the entire multiline prompt, then
  # moves cursor to current y

  #editor.events.call(jePreFullRender)

  let lastY = min(editor.content.high(), editor.vscroll + editor.getVmax() - 1)
  for i in countup(editor.vscroll, lastY):
    editor.render(i)
    if i - editor.vscroll < editor.rendered:
      cursorDown(1)
    else:
      write stdout, "\n"
      inc editor.rendered

  let rendered = lastY - editor.vscroll + 1
  var extraup = 0
  while rendered < editor.rendered:
    eraseLine()
    cursorDown(1)
    dec editor.rendered
    inc extraup

  # return to the selected y pos
  cursorUp(lastY + 1 - editor.content.Y + extraup)

proc moveCursorToEnd(editor: LineEditor) =
  # only called when read finished
  if editor.content.high() > editor.content.Y:
    cursorDown(editor.content.high() - editor.content.Y)
  write stdout, "\n"



proc bindRenderer*(le: LineEditor) =

  var
    preY: int
    preVScroll: int
  
  le.evtTable.subscribe(jePreRead):
    le.fullRender()

  le.evtTable.subscribe(jePreKeypress):
    setCursorXPos(le.content.X - le.hscroll + le.prompt.len())
    preY = le.content.Y
    preVScroll = le.vscroll

  le.evtTable.subscribe(jeKeypress):
    discard

  le.evtTable.subscribe(jePostKeypress):
    # scrolling
    # last X that can be rendered on the screen
    let lastX = terminalWidth() - le.prompt.len() + le.hscroll - 1
    # first X to be rendered
    let firstX = le.hscroll
    # X index put in bounds
    let boundX = min(max(firstX, le.content.X), lastX)
    # if outside of bounds
    if le.content.X != boundX:
      # scroll to move it inside bounds
      le.hscroll += le.content.X - boundX
      # if all lines scroll horizontally, full redraw is neccessary
      if le.horizontalScrollMode == hsbAllScroll:
        le.redraw()

    # first Y to be rendered
    let firstY = le.vscroll
    # last Y to be (potentially) rendered
    let lastY = le.vscroll + le.getVmax() - 1
    # Y index put into bounds
    let boundY = min(max(firstY, le.content.Y), lastY)
    # Y outside of bounds:
    if le.content.Y != boundY:
      # scroll vertically to move it inside bounds
      le.vscroll += le.content.Y - boundY
      # vertical scrolling always means full redraw
      le.redraw()

    # actual redraw handling
    if le.forceRedraw or preY != le.content.Y or preVScroll != le.vscroll:
      # move to the top
      if preY - preVScroll > 0:
        cursorUp(preY - preVScroll)
      # redraw everything
      le.fullRender()
      if le.forceRedraw:
        le.forceRedraw = false
    else:
      # redraw a single line
      le.render()

  le.evtTable.subscribe(jePostRead):
    le.moveCursorToEnd()

  le.evtTable.subscribe(jeResize):
    le.redraw()

