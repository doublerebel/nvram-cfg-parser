# nvram-cfg-parser
## Command line parser for Tomato Firmware NVRAM cfg backups

### What it does

Decodes Tomato cfg files into JSON so they can be changed and compared against other backups.  Encodes JSON-formatted Tomato cfg key/value pairs into the Tomato cfg format.

### Installation

nvram-cfg-parser is available from npm, the standard package manager included with [nodejs](http://nodejs.org/download/).

Install from npm:

    # npm install -g nvram-cfg-parser

### Usage:

#### decode

nvramcfg **decode** `<filename>`

Command example:

    $ nvramcfg decode tomato_v128_m943394.cfg

Output example (keys in no particular order):

```json
{
  "0|31|||word text\n^begins-with.domain.\n.ends-with.net$\n^www.exact-domain.net$|0|exampl": "|1320|300|31|||word text\n^begins-with.domain.\n.ends-with.net$\n^www.exact-domain.net$|0|example",
  "wl_mac_deny": "",
  "wl_radius_port": "1812",
  "sb/1/ofdm2gpo": "0x44444444",
  "pptp_client_mru": "1450",
  "https_crt": "",
  "qos_reset": "1",
  ...
```

#### decode to file

    $ nvramcfg decode tomato_v128_m943394.cfg > tomato_v128_m943394.json

#### encode

nvramcfg **encode** `<format>` `<filename>`

Command example:

    $ nvramcfg encode arm tomato_v128_m943394-altered.json > tomato_v128_m943394-altered.cfg

Supported formats are [`original` and `arm`](#faq).


#### colorized json diff

nvramcfg **diff** `<filename1>` `<filename2>`

Command example:

    $ nvramcfg diff tomato_v128_m943394.json tomato_v128_m943394-altered.json

Output example

```diff
 {
-  router_name: "TomatoUSB"
+  router_name: "ExampleName"
 }
```

### How it works

#### Original

The tomato_vxxx_xxxxx.cfg files are gzipped utf-8 text with null characters bounding and separating the key=value pair sets.  We unzip the file, strip the header and footer, and read the null-separated key=value pairs.

#### ARM

The tomato_vxxx_xxxxx.cfg files are not gzipped, but are an obfuscated version of the original utf-8-with-null-separators.  We read the random value and de-obfuscate back to the original format.

### Programmatic usage in JavaScript

Decode and encode are available from the NvramParser class.  See comments in `src/nvram-parser.iced`, `src/nvram-arm-parser.iced`,  for details.

### FAQ

  * How to tell if my router build is ARM format?

  The tomato builds for your router contain **ARM** in the filename.  Example: `tomato-RT-AC56U-AT-ARM-2.7-128-AIO-64K.trx`

### License

MIT Licensed.  Use at your own risk.
