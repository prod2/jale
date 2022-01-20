# editor.nim

import types/event
import types/multiline
import terminal
import keycodes
import sequtils

when defined(posix):
  import posix

type
  JaleState = enum
    jsInactive, jsActive, jsFinishing, jsQuitting

  
  HorizontalScrollBehavior* = enum
    hsbSingleScroll, hsbAllScroll, hsbWrap

  LineEditorObj* = object
    # permanent across reads
    evtTable*: EventTable
    prompt*: string
    horizontalScrollMode*: HorizontalScrollBehavior

    # change across every read() call
    content*: Multiline
    lastKeystroke*: int # TODO potentially deprecate
    state: JaleState
    hscroll*: int
    vscroll*: int
    vmax: int # maximum amount of vertical screen space

    # TODO remove the need for these through events
    rendered*: int # how many lines were printed last full refresh
    forceRedraw*: bool

  LineEditor* = ref LineEditorObj

# weak list of references
var editors: seq[ptr LineEditorObj]

# constructors and related code

proc reset*(le: LineEditor) =
  # called when read() is over
  le.state = jsInactive
  le.rendered = 0 # TODO deprecate
  le.content = newMultiline()
  le.lastKeystroke = -1 # TODO deprecate
  le.forceRedraw = false # TODO deprecate
  
  le.hscroll = 0
  le.vscroll = 0

proc finalizer (inst: LineEditor) =
  editors = editors.filterIt(cast[ptr LineEditorObj](inst) != it)

proc newLineEditor*: LineEditor =
  new(result, finalizer)
  result.reset()
  result.evtTable = newEventTable()
  result.prompt = ""
  result.horizontalScrollMode = hsbSingleScroll
  result.vmax = 0
  editors.add(cast[ptr LineEditorObj](result))

# resize event firing
when defined(posix):
  onSignal(28):
    for ed in editors:
      discard ed.evtTable.callRaw(jeResize, @[])
      
# getters/setters

proc getVmax*(le: LineEditor): int =
  if le.vmax <= 0:
    terminalHeight() + le.vmax
  else:
    le.vmax

proc setVmax*(le: LineEditor, val: int) =
  le.vmax = val
  

# methods

proc unfinish*(le: LineEditor) =
  le.state = jsActive

proc finish*(le: LineEditor) =
  le.state = jsFinishing
  discard le.evtTable.callRaw(jeFinish, @[])

proc quit*(le: LineEditor) =
  le.state = jsQuitting
  discard le.evtTable.callRaw(jeQuit, @[])

# TODO: deprecate
proc redraw*(le: LineEditor) =
  le.forceRedraw = true

proc read*(le: LineEditor): string =
  le.state = jsActive
  discard le.evtTable.callRaw(jePreRead, @[])
  while le.state == jsActive:

    discard le.evtTable.callRaw(jePreKeypress, @[])
    let key = getKey()
    le.lastKeystroke = key # TODO deprecate
    discard le.evtTable.callRaw(jeKeypress, @[JaleObject(kind: jkInt, intVal: key)])
    discard le.evtTable.callRaw(jePostKeypress, @[])

  discard le.evtTable.callRaw(jePostRead, @[])

  if le.state == jsFinishing:
    result = le.content.getContent()
  le.reset()
