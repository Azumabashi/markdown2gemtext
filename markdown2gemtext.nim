import os
import markdown
import re
import strformat
import strutils

proc replaceHeaders(content: string, level: int): string =
  let
    beginSymbol = fmt"<h{level}>"
    endSymbol = fmt"</h{level}>"
  result = content.replacef(re(fmt"{beginSymbol}(.*){endSymbol}"), "* $1")

proc markdown2gemtext(path: string): string =
  var file = open(path, FileMode.fmRead)
  defer:
    close(file)
  let html = markdown(file.readAll())

discard markdown2gemtext("sample/sample.md")
