# event.nim

# Using async is not needed, since the only events that happen are key presses
# and terminal resizes, while all other operations should complete reasonably fast.
# If you need to include jale in a larger async program, it is advised to read those
# yourself and feed them to jale (sort of reimplementing the editor main loop part).

import tables

type
  JaleEvent* = enum
    jeQuit, jeFinish,
    jePreKeypress, jeKeypress, jePostKeypress,
    jePreRead, jePostRead,
    jeResize

  JaleKind* = enum
    jkInt, jkChar, jkString, jkVoid

  JaleObject* = object
    case kind*: JaleKind:
      of jkInt:
        intVal*: int
      of jkChar:
        charVal*: char
      of jkString:
        stringVal*: string
      of jkVoid:
        discard

  EventTable* = TableRef[JaleEvent, seq[proc (args: seq[JaleObject]): JaleObject]]

proc newEventTable*: EventTable =
  new(result)

proc subscribeRaw*(evtTable: EventTable, event: JaleEvent, action: proc(args: seq[JaleObject]): JaleObject) =

  if not evtTable.hasKey(event):
    evtTable[event] = @[]
  evtTable[event].add(action)
  
template subscribe*(evtTable: EventTable, event: JaleEvent, body: untyped) =
  proc action (args {.inject.}: seq[JaleObject]): JaleObject {.gensym.} =
    result = JaleObject(kind: jkVoid)
    body

  evtTable.subscribeRaw(event, action)


proc callRaw*(evtTable: EventTable, event: JaleEvent, args: seq[JaleObject]): seq[JaleObject] =
  result = @[]
  if evtTable.hasKey(event):
    for callback in evtTable[event]:
      result.add(callback(args))
