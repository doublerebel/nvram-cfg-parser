###
format begins with 54 43 46 31 0C
  TCF1 and OC
  then 3 nulls

then key value pairs separated by nulls

format ends with two nulls
  first null normal line end
  second null signifies EOF
###

fs   = require 'fs'
zlib = require 'zlib'
buffertools = require 'buffertools'


class NvramParser
  # pretty-print JSON?
  @pretty: false

  @error: (e) -> console.error "error: #{e}"

  @formatHexString: (hexstring) -> hexstring.toLowerCase().replace /\s/g, ""

  # define format
  @header: "54 43 46 31 0C 00 00 00"
  @footer: "00 00"
  @headerbuf: buffertools.fromHex new Buffer @formatHexString @header
  @footerbuf: buffertools.fromHex new Buffer @formatHexString @footer
  @separator: "\u0000"

  # validate that buffer is bookended by header/footer
  @validate: (buf) ->
    return "object not a Buffer" unless buf instanceof Buffer

    unless buffertools.equals (h = buf[0..@headerbuf.length-1]), @headerbuf
      return "header \"#{h}\" does not match expected NVRAM cfg format -- aborting"

    unless buffertools.equals (f = buf[-@footerbuf.length..]), @footerbuf
      return "footer \"#{f}\" does not match expected NVRAM cfg format -- aborting"

    true

  # (async) load file and return unzipped buffer
  @loadFile: (filename, autocb) ->
    fz = fs.readFileSync filename
    await zlib.gunzip fz, defer err, buf
    return err if err
    buf

  # parse buffer
  @parse: (buf) =>
    body = buf[@headerbuf.length..-@footerbuf.length]
    bound = 0
    settings = {}

    # loop through each null character
    while bound < body.length
      bound = buffertools.indexOf body, @separator, 0
      break if bound < 0

      # slice pair and remaining body from each side of null char
      pair = body[..bound-1]
      body = body[bound+1..]

      # slice pair at first index of "=" ("=" is valid char in value after "=")
      pair = pair.toString "utf8"
      eq   = pair.indexOf "="
      key  = pair[..eq-1]
      val  = pair[eq+1..]
      settings[key] = val

    settings

  # (async) load file and return JSON string of key/value pairs
  @decode: (filename, autocb) =>
    await @loadFile filename, defer buf
    valid = @validate hex_f
    return @error valid unless valid is true

    settings = @parse buf
    if @pretty then JSON.stringify settings, null, 2
    else            JSON.stringify settings

  # (async) load JSON file and pack in Tomato NVRAM cfg binary format
  @encode: (filename, autocb) =>
    json = fs.readFileSync filename
    settings = JSON.parse json

    # create buffer from key:value pairs and append null char
    pairs = for key, value of settings
      pair = new Buffer "#{key}=#{value}"
      buffertools.concat pair, @separator

    # strip null character from last line or tomato complains "Extra data found at the end."
    last = pairs[pairs.length-1]
    pairs[pairs.length-1] = last[..-2]

    # bookend key=value pairs with header/footer
    buf = buffertools.concat @headerbuf, pairs..., @footerbuf
    await zlib.gzip buf, defer err, fz
    return error err if err
    fz


module.exports = NvramParser
