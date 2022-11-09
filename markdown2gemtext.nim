import os
import markdown
import re
import strformat
import strutils

var linkId = 1

proc replaceHeaders(content: string, level: int): string =
  let
    beginSymbol = fmt"<h{level}>"
    endSymbol = fmt"</h{level}>"
    leading = "#".repeat(level)
  result = content.replacef(re(fmt"{beginSymbol}(.*){endSymbol}"), fmt"{leading} $1")

proc replaceLists(content: string): string =
  result = content.replacef(re("<li>(.*)</li>"), "* $1")
  result = result.replace("<ul>", "").replace("</ul>", "")

proc replaceQuotes(content: string): string =
  result = content
  let quotes = content.findAll(re"<blockquote>(.|\n)*</blockquote>")
  for quote in quotes:
    var parsed = quote.replacef(re"</?blockquote>\n?", "").replacef(re"<p>((.|\n)*)</p>", "> $1").replace("\n", "\n> ")
    parsed = parsed[0 ..< parsed.len - 2]  # remove last line of ">\n"
    result = result.replace(quote, parsed)

proc replaceLinks(rawContent: string): string =
  var contents = rawContent.split("\n")
  let regex = re("(.*)<a href=\"(.*)\">(.*)</a>(.*)")
  for i in 0..<contents.len:
    if contents[i].match(regex):
      contents[i] = contents[i].replacef(regex, fmt"$1$3[{linkId}]$4\n=> $2 {linkId}: $2\n")
      linkId += 1
  result = contents.join("\n")

proc removePTag(content: string): string =
  result = content.replacef(re".*<p>(.*)</p>.*", "$1")

proc markdown2gemtext(path: string): string =
  var file = open(path, FileMode.fmRead)
  defer:
    close(file)
  let html = markdown(file.readAll())
  result = html
             .replaceHeaders(1)
             .replaceHeaders(2)
             .replaceHeaders(3)
             .replaceLists
             .replaceQuotes
             .replaceLinks
             .removePTag

if isMainModule:
  for target in os.commandLineParams():
    let result = markdown2gemtext(target)
    var file = open("html/" & target.replacef(re"(.*\.)md", "$1gmi"), FileMode.fmWrite)
    defer:
      close(file)
    file.writeLine(result)
    echo target, " converted!"
