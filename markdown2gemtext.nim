import os
import markdown
import nre
import strformat
import strutils
import uri

var linkId = 1

proc replaceHeaders(content: string, level: int): string =
  let
    beginSymbol = fmt"<h{level}>"
    endSymbol = fmt"</h{level}>"
    leading = "#".repeat(level)
  result = content.replace(re(fmt"{beginSymbol}(.*){endSymbol}"), proc (m: RegexMatch): string =
    return fmt"{leading} {m.captures[0]}"
  )

proc replaceLists(content: string): string =
  result = content.replace(re("<li>(.*)</li>"), proc (m: RegexMatch): string = 
    return fmt"* {m.captures[0]}"
  )
  result = result.replace("<ul>", "").replace("</ul>", "")

proc replaceQuotes(content: string): string =
  result = content
  let quotes = content.findAll(re"<blockquote>(.|\n)*</blockquote>")
  for quote in quotes:
    var parsed = quote.replace(re"</?blockquote>\n?", "").replace(re"<p>((.|\n)*)</p>", proc (m: RegexMatch): string = 
      return fmt"> {m.captures[0]}"
    ).replace("\n", "\n> ")
    parsed = parsed[0 ..< parsed.len - 2]  # remove last line of ">\n"
    result = result.replace(quote, parsed)

proc replaceLinks(rawContent: string): string =
  var 
    contents = rawContent.split("\n")
    links: seq[string] = @[]
    isMatched = false
  let regex = re("(.*?)<a href=\"(.*?)\">(.*?)</a>(.+)")
  for i in 0..<contents.len:
    isMatched = false
    links = @[]
    while contents[i].match(regex).isSome:
      isMatched = true
      contents[i] = contents[i].replace(regex, proc (m: RegexMatch): string = 
        let 
          match = m.captures
          isLink2Gemini = match[1].endsWith(".gmi") or match[1].startsWith("gemini://")
          protocolShow = if not isLink2Gemini: " (outer of gemini)" else: ""
        links.add(fmt"=> {match[1]} {linkId}: {match[1]}{protocolShow}")
        return fmt"{match[0]}{match[2]}[{linkId}]{match[3]}"
      )
      linkId += 1
    if isMatched:
      contents[i] = contents[i] & "\n" & links.join("\n") & "\n"
  result = contents.join("\n")

proc removePTag(content: string): string =
  result = content.replace(re".*<p>(.*)</p>.*", proc (m: RegexMatch): string = 
    return m.captures[0]
  )

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
    let
      result = markdown2gemtext(target)
      savePath = "gemtext/" & target.replace(re"(.*\.)md", proc (m: RegexMatch): string = 
        return fmt"{m.captures[0]}gmi"
      )
      dirPath = splitFile(savePath).dir
    createDir(dirPath)
    var file = open(savePath, FileMode.fmWrite)
    defer:
      close(file)
    file.writeLine(result)
    echo target, " converted!"
    linkId = 1
