import os
import markdown
import re
import strformat
import strutils

proc replaceHeaders(content: string, level: int): string =
  let
    beginSymbol = fmt"<h{level}>"
    endSymbol = fmt"</h{level}>"
    leading = "#".repeat(level)
  result = content.replacef(re(fmt"{beginSymbol}(.*){endSymbol}"), "{leading} $1")

proc replaceLists(content: string): string =
  result = content.replacef(re("<li>(.*)</li>"), "* $1")
  result = result.replace("<ul>", "").replace("</ul>", "")

proc replaceQuotes(content: string): string =
  result = content
  let quotes = content.findAll(re"<blockquote>(.|\n)*</blockquote>")
  echo quotes
  for quote in quotes:
    var parsed = quote.replacef(re"</?blockquote>\n?", "").replacef(re"<p>((.|\n)*)</p>", "> $1").replace("\n", "\n> ")
    parsed = parsed[0 ..< parsed.len - 2]  # remove last line of ">\n"
    result = result.replace(quote, parsed)

proc markdown2gemtext(path: string): string =
  var file = open(path, FileMode.fmRead)
  defer:
    close(file)
  let html = markdown(file.readAll())
  discard html.replaceQuotes

discard markdown2gemtext("sample/sample.md")
