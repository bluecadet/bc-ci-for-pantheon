// Require the node file system
var fs = require('fs');

module.exports.build = function (url_data, liveURL, multidevURL) {

  // grab template file.
  var rootPath = process.cwd();

  var fileContents = fs.readFileSync(rootPath + '/tests/backstopjs/backstop.default.json');
  var config = JSON.parse(fileContents);

  // console.log(config);

  // Add scenarios
  let defaultScenario = config.scenarios[0];
  let newScenarios = [];

  url_data.forEach(function (el) {
    var scenario = defaultScenario;

    // Set testing URL
    if (isRelativeURL(el.path)) {
      scenario.url = multidevURL + "/" + el.path;
    }
    else {
      scenario.url = el.path;
    }

    // Set Live URL
    if (isRelativeURL(el.path)) {
      scenario.referenceUrl = liveURL + "/" + el.path;
    }
    else {
      scenario.referenceUrl = el.path;
    }

    // Set label.
    scenario.label = (el.label) ? el.label : el.path;

    // Add to config.
    newScenarios.push(JSON.parse(JSON.stringify(scenario)));
  });

  // Reset Scenarios.
  config.scenarios = newScenarios;

  // write used file.
  fs.writeFileSync(rootPath + '/tests/backstopjs/backstop.json', JSON.stringify(config, null, 2));
  console.log("Successfuly created " + rootPath + '/tests/backstopjs/backstop.json');
};
