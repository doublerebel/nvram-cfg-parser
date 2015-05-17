fs   = require 'fs'
buffertools = require 'buffertools'


class NvramArmParser

  @error: (e) -> console.error "error: #{e}"
  # ASUS ARM NVRAM header
  @header: "HDR2"
  @is: (buf) -> buffertools.equals buf[0..3], @header

  # https://bitbucket.org/pl_shibby/tomato-arm/src/af1859afbb4d48bd0e6e65e16d9f1005f65a4e43/release/src-rt-6.x.4708/router/nvram_arm/main.c?at=shibby-arm#cl-134
  @decode: (buf, autocb) ->
    unless buf instanceof Buffer
      buf = fs.readFileSync buf
      return @error "invalid header, expected HDR2" unless @is buf

    # Header format is 8 bytes:
    # - first 4 are @header
    # - next 3 are long int for remainder file length
    # - last byte is random char for obfuscation
    filelenptr = @header.length
    filelen    = buf.readUInt32BE filelenptr, 3
    randptr    = filelenptr + 3
    rand       = buf[randptr]

    for i in [8..filelen+7]
      if buf[i] > (0xfd - 0x1)
        if i is lastgarbage + 1
          return buf[0..i-1]
        buf[i] = 0x0
        lastgarbage = i
      else
        buf[i] = 0xff + rand - buf[i]

    buf

  # https://bitbucket.org/pl_shibby/tomato-arm/src/af1859afbb4d48bd0e6e65e16d9f1005f65a4e43/release/src-rt-6.x.4708/router/nvram_arm/main.c?at=shibby-arm#cl-49
  @get_rand: -> Math.round Math.random() * 0xff

  @encode: (pairs, autocb) ->
    pairsbuf = buffertools.concat pairs...
    count    = pairsbuf.length
    filelen  = count + (1024 - count % 1024)
    rand     = @get_rand() % 30

    filelenbuf = new Buffer 3
    filelenbuf.writeUInt32BE filelen, 0, 3
    header = buffertools.concat @header, filelenbuf, new Buffer [rand]
    footer = new Buffer filelen - count
    footer[i] = 0xfd + @get_rand() % 3 for i in footer

    for byte, i in pairsbuf
      if byte is 0x0
        pairsbuf[i] = 0xfd + @get_rand() % 3
      else
        pairsbuf[i] = 0xff - pairsbuf[i] + rand

    buffertools.concat header, pairsbuf, footer


module.exports = NvramArmParser
