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

  # define format
  @header: "54 43 46 31 0C 00 00 00".toLowerCase().replace /\s/g, ""
  @footer: "00 00".replace " ", ""

  # validate that hexstring/hexbuffer is bookended by header/footer
  @validate: (hexstring) ->
    if (h = hexstring[0..@header.length-1]) isnt @header
      return "header \"#{h}\" does not match expected NVRAM cfg format -- aborting"

    else if (f = hexstring[-@footer.length..]) isnt @footer
      return "footer \"#{f}\" does not match expected NVRAM cfg format -- aborting"

    true

  # load file and return unzipped buffer
  @loadFile: (filename, autocb) ->
    fz = fs.readFileSync filename
    await zlib.gunzip fz, defer err, buf
    return err if err
    buf

  # parse buffer
  @parse: (hexbuffer) ->
    body = hexbuffer[@header.length..-@footer.length-2]
    bound = 0
    settings = {}

    # loop through each null character
    while bound < body.length
      bound = buffertools.indexOf body, "\u0000", 0
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

  # load file and return JSON string of key/value pairs
  @decode: (filename, autocb) =>
    await @loadFile filename, defer buf
    return @error buf unless buf instanceof Buffer

    hex_f = buffertools.toHex buf
    valid = @validate hex_f
    return @error valid unless valid is true

    settings = @parse buf
    if @pretty then JSON.stringify settings, null, 2
    else            JSON.stringify settings

  # load JSON file and pack in Tomato NVRAM cfg format
  @encode: (filename, autocb) ->
    json = fs.readFileSync filename
    settings = JSON.parse json

    # create buffer from key:value pairs and append null char
    pairs = for key, value of settings
      pair = new Buffer "#{key}=#{value}"
      buffertools.concat pair, "\u0000"

    # strip null character from last line or tomato complains "Extra data found at the end."
    last = pairs[pairs.length-1]
    pairs[pairs.length-1] = last[..-2]

    # bookend key=value pairs with header/footer
    buf = buffertools.concat (buffertools.fromHex new Buffer @header), pairs..., (buffertools.fromHex new Buffer @footer)
    await zlib.gzip buf, defer err, fz
    return error err if err
    fz


module.exports = NvramParser
