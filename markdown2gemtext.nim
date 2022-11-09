import os
import markdown
import re
import strformat
import strutils

proc replaceHeaders(content: string, level: int): string =
  let
    beginSymbol = fmt"<h{level}>"
    endSymbol = fmt"</h{level}>"
    matches = content.findAll(re(fmt"{beginsymbol}.*{endSymbol}"))
  result = content
  for match in matches:
    let deletedSymbol = match.replace(beginSymbol, "").replace(endSymbol, "")
    result = content.replace(match, "*".repeat(level) & " " & deletedSymbol)

proc markdown2gemtext(path: string): string =
  var file = open(path, FileMode.fmRead)
  defer:
    close(file)
  let html = markdown(file.readAll())


discard markdown2gemtext("sample/sample.md")
