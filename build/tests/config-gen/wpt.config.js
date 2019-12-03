// Require the node file system
var fs = require('fs');

module.exports.build = function (url_data, liveURL, multidevURL) {

  // grab template file.
  let rootPath = process.cwd();

  let fileContents = fs.readFileSync(rootPath + '/tests/web-page-test/wpt.default.json');
  let config = JSON.parse(fileContents);

  let defaultConfig = JSON.parse(JSON.stringify(config));
  delete defaultConfig.urls;

  // add urls
  url_data.forEach(function (el) {
    if (el.wptOptIn == true) {

      let scenario = JSON.parse(JSON.stringify(defaultConfig));

      if (isRelativeURL(el.path)) {
        scenario.url = liveURL + "/" + el.path;
      }
      else {
        scenario.url = el.path;
      }

      if (el.label) {
        scenario.label = el.label;
      }

      // Add to config.
      config.urls.push(JSON.parse(JSON.stringify(scenario)));
    }
  });

  // write used file.
  fs.writeFileSync(rootPath + '/tests/web-page-test/wpt.json', JSON.stringify(config, null, 2));

};
