# history.nim

import ../types/multiline

import os
import options

type HistoryElement* = ref object
  original*: Multiline
  current*: Multiline
  temp: bool

type History* = ref object
  elements: seq[HistoryElement]
  index: int
  lowestTouchedIndex: int

proc newHistory*: History =
  new(result)
  result.index = 0
  result.lowestTouchedIndex = 0
  result.elements = @[]

template newIndex(h: History): Option[Multiline] =
  if h.lowestTouchedIndex > h.index:
    h.lowestTouchedIndex = h.index

  some(h.elements[h.index].current)

proc delta*(h: History, amt: int): Option[Multiline] =
  # move up/down in history and return reference to current
  # also update lowest touched index
  if h.elements.len() == 0:
    return none[Multiline]()

  if h.index + amt <= 0:
    h.index = 0
  elif h.index + amt >= h.elements.high():
    h.index = h.elements.high()
  else:
    h.index += amt
  h.newIndex()
  

proc toEnd*(h: History): Option[Multiline] =
  if h.elements.len() == 0:
    return none[Multiline]()
  h.index = h.elements.high()
  h.newIndex()

proc toStart*(h: History): Option[Multiline] =
  if h.elements.len() == 0:
    return none[Multiline]()
  h.index = 0
  h.newIndex()

proc clean*(h: History) =
  # restore originals to current
  # from lowest touched index to the top

  if h.lowestTouchedIndex <= h.elements.high():
    for i in countup(h.lowestTouchedIndex, h.elements.high()):
      if h.elements[i].temp:
        h.elements.delete(i)
      else:
        h.elements[i].current = h.elements[i].original.copy()
  
  h.lowestTouchedIndex = h.elements.len()

proc newEntry*(h: History, ml: Multiline, temp: bool = false) =
  if not temp:
    h.elements.add(HistoryElement(original: ml, current: ml.copy(), temp: temp))
  else:
    h.elements.add(HistoryElement(original: ml, current: ml, temp: temp))

proc save*(h: History, path: string) =
  # discards currents and temps, only saves originals
  if dirExists(path):
    raise newException(CatchableError, "Attempt to save history to " & path & ", but a directory at that path exists")

  let file = open(path, fmWrite)

  for el in h.elements:
    if el.temp:
      continue
    file.writeLine(el.original.serialize())

  file.close()

proc loadHistory*(path: string): History =
  if not fileExists(path):
    raise newException(CatchableError, "Attempt to read history from a non-existant file")
  let file = open(path, fmRead)
  
  let h = newHistory()
  var line: string
  while readLine(file, line):
    h.newEntry(line.deserialize())

  file.close()
  return h
