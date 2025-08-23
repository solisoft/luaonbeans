const opentype = require('opentype.js');

opentype.load(process.argv[2], function (err, font) {
  var codes = {}

  for(let i = 32; i < 257; i++) {
    codes[i] = font.getAdvanceWidth(String.fromCharCode(i), 1000)
  }
  console.log(JSON.stringify(codes))
})