import mummy, mummy/routers
import strutils, std/mimetypes, os
# import print
import strformat

when (NimMajor, NimMinor, NimPatch) >= (1,9,3):
  # Mimetypes is a ref on older versions
  const m = newMimetypes()

template return404() =
  headers["Content-Type"] = "text/plain"
  request.respond(404, headers, "not found")
  return


proc staticFileHandler*(request: Request) =
  ## A static file handler for mummy.
  ## The file(s) must be readable by others to be served.
  ##
  ## Usage:
  ## ..code::
  ##   import mummy, mummy/routers
  ##   import mummStaticFiles
  ##
  ##   var router: Router
  ##   # All your static files will be served from the "static" folder
  ##   router.get("/static/**", staticFileHandler)
  ##
  ##   let server = newServer(router)
  ##   echo "Serving on http://localhost:7878"
  ##   server.serve(Port(7878))
  ##
  ##
  var path = request.uri
  var headers: HttpHeaders

  if path.contains(".."):
    return404

  let ext = path.splitFile().ext

  when (NimMajor, NimMinor, NimPatch) <= (1,9,3):
    # Mimetypes is a ref on older versions
    let m = newMimetypes()
  let mimetype = m.getMimeType(ext)
  let filePath = getAppDir() / path

  # {.gcsafe.}:
  #   print path, request.uri, ext, mimetype, filePath

  if not fileExists(filePath):
    return404

  var fp = getFilePermissions(filePath)
  if not fp.contains(fpOthersRead):
    return404

  headers["Content-Type"] = mimetype
  headers["Content-Length"] = $getFileSize(filePath)
  request.respond(200, headers, readFile(filePath))

when isMainModule:
  var router: Router
  router.get("/static/**", staticFileHandler)

  let server = newServer(router)
  echo "Serving on http://localhost:7878"
  server.serve(Port(7878))
