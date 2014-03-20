#!/usr/bin/env node

var NvramParser, action, die, filename, print,
    spawn = require('child_process').spawn,
    jsonDiffPath = "node_modules/json-diff/bin/json-diff.js";

print = function(s) {
  console.log(s);
};
dump = function(b) {
  process.stdout.write(b);
}

NvramParser = require("./nvram-parser");
NvramParser.pretty = true;

die = function(e) {
  NvramParser.error(e);
  process.exit(1);
};

action = process.argv[2];

if (!action) {
  die("must specify action");
}

filename = process.argv[3];

if (!filename) {
  die("must specify filename");
}

switch (action) {
  case "decode":
    NvramParser.decode(filename, print);
    break;
  case "encode":
    NvramParser.encode(filename, dump);
    break;
  case "diff":
    if (!process.argv[4]) {
      die("must specify 2nd filename");
    }
    require('json-diff/lib/cli')(process.argv.slice(3));
    break;
  default:
    die("invalid action " + action);
}
