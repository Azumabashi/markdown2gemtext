import os
import nre
import strformat
import strutils
import uri
import lib/types
import sequtils

var 
  linkId = 1
  targets: seq[string] = @[]
  relativeAddresses: seq[string] = @[]
  baseUri = ""

proc replaceLists(content: string): string =
  result = content.replace(re("- (.*)"), proc (m: RegexMatch): string = 
    return fmt"* {m.captures[0]}"
  )
  result = result.replace("<ul>", "").replace("</ul>", "")

proc parseUri(uri: string): UriInfo = 
  var parsedUri = initUri()
  uri.parseUri(parsedUri)
  result = UriInfo(
    scheme: parsedUri.scheme,
    hostname: parsedUri.hostname,
    path: parsedUri.path,
    isAbsolute: parsedUri.isAbsolute
  )

proc replaceLinks(rawContent: string, filepath: string, searchDir: string): string =
  var 
    contents = rawContent.split("\n")
    links: seq[string] = @[]
    isMatched = false
  let regex = re"(.*?)\[(.*?)\]\((.*?)\)(.*)"
  for i in 0..<contents.len:
    isMatched = false
    links = @[]
    while contents[i].match(regex).isSome:
      isMatched = true
      contents[i] = contents[i].replace(regex, proc (m: RegexMatch): string = 
        let match = m.captures
        var address = match[2]
        let 
          parsedUri = address.parseUri
          isLink2Gemini = address.endsWith(".gmi") or parsedUri.scheme == "gemini" or address in relativeAddresses
          protocolShow = if not isLink2Gemini: " (out of gemini)" else: ""
        if isLink2Gemini and not parsedUri.isAbsolute:
          address = address[0..<address.len-1] & ".gmi"
        elif not parsedUri.isAbsolute:
          address = baseUri & address
        links.add(fmt"=> {address} {linkId}: {address}{protocolShow}")
        return fmt"{match[0]}{match[1]}[{linkId}]{match[3]}"
      )
      linkId += 1
    if isMatched:
      contents[i] = contents[i] & "\n" & links.join("\n") & "\n"
  result = contents.join("\n")

proc removePTag(content: string): string =
  result = content.replace(re".*<p>(.*)</p>.*", proc (m: RegexMatch): string = 
    return m.captures[0]
  )

proc markdown2gemtext*(path: string, searchDir: string): string =
  var file = open(path, FileMode.fmRead)
  defer:
    close(file)
  result = file.readAll()
             .replaceLists
             .replaceLinks(path, searchDir)
             .removePTag

if isMainModule:
  let 
    argv = commandLineParams()
    searchDir = argv[0]
  baseUri = argv[1]
  for file in walkDirRec(searchDir):
    if file.endsWith(".md"):
      targets.add(file)
  
  relativeAddresses = targets.map(proc(path: string): string = 
    path[searchDir.len ..< path.len-3] & "/"
  )
  
  for target in targets:
    let
      result = markdown2gemtext(target, searchDir)
      savePath = if argv.len >= 3:
         argv[2] & "/" & target.splitFile.name & ".gmi"
        else: 
          "gemtext/" & target.replace(re"(.*\.)md", proc (m: RegexMatch): string = 
            return fmt"{m.captures[0]}gmi"
          )
      dirPath = splitFile(savePath).dir
    createDir(dirPath)
    var file = open(savePath, FileMode.fmWrite)
    defer:
      close(file)
    file.writeLine(result)
    echo target, " => ", savePath
    linkId = 1
