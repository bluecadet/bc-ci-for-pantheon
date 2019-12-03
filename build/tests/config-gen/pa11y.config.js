// Require the node file system
var fs = require('fs');

module.exports.build = function (url_data, liveURL, multidevURL) {

  // grab template file.
  var rootPath = process.cwd();

  var fileContents = fs.readFileSync(rootPath + '/tests/pa11y/.pa11yci.default.json');
  var config = JSON.parse(fileContents);

  // add urls
  url_data.forEach(function (el) {
    if (isRelativeURL(el.path)) {
      config.urls.push(multidevURL + "/" + el.path);
    }
    else {
      config.urls.push(el.path);
    }
  });

  // write used file.
  fs.writeFileSync(rootPath + '/tests/pa11y/.pa11yci.json', JSON.stringify(config, null, 2));

};
