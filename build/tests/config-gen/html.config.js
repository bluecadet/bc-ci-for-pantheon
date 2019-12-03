// Require the node file system
var fs = require('fs');

module.exports.build = function (url_data, liveURL, multidevURL) {

  // grab template file.
  var rootPath = process.cwd();

  var fileContents = fs.readFileSync(rootPath + '/tests/html-validation/html-config.default.json');
  var config = JSON.parse(fileContents);

  // add urls
  url_data.forEach(function (el) {
    if (isRelativeURL(el.path)) {
      config.push(multidevURL + "/" + el.path);
    }
    else {
      config.push(el.path);
    }
  });

  // write used file.
  fs.writeFileSync(rootPath + '/tests/html-validation/html-config.json', JSON.stringify(config, null, 2));

};
