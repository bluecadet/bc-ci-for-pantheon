const { HtmlUrlChecker } = require('broken-link-checker');
const https = require('https');
const fsx = require('fs-extra');
const path = require('path');

let report_dir = process.argv[3];
fsx.ensureDirSync(report_dir);
let report_filename = process.argv[4];

console.log(report_dir, report_filename);

let errors = [];
let links = [];

let options = {
  filterLevel: 0,
};

let count = 0;
let countMax = 0;

var htmlUrlChecker = new HtmlUrlChecker(options, {
  html: function (tree, robots, response, pageUrl, customData) { },
  junk: function (result, customData) { },
  link: function (result, customData) {
    // Log Errors.
    if (result.broken) {
      // console.log(result);
      errors.push({
        url: result.url.resolved,
        base: result.base.resolved,
        brokenReason: result.brokenReason,
      });
    }

  },
  page: function (error, pageUrl, customData) {
    // For long runs, CircleCI needs some output.
    if (count % 10 == 0) {
      console.log("Working on " + count + " out of " + countMax + "...");
    }
    count++;
  },
  end: function () {

    let reportData = {
      msg: "",
      linkCount: links.length,
      links: links,
      errorCount: 0,
      errors: [],
    };

    if (errors.length > 0) {
      reportData.msg = "There were errors";
      reportData.errors = errors;
      reportData.errorCount = errors.length;
    }
    else {
      reportData.msg = "No errors, nothing to report";
    }

    // Save Report.
    let report = JSON.stringify(reportData, null, 2);
    fsx.writeFileSync(path.join(report_dir, report_filename), report);
  }
});

// Grab URLs from Connect Site.
let domain = process.argv[2];
let connUrl = process.env.CONNECT_BC_DOMAIN;
let connHost = process.env.CONNECT_BC_HOST;
let connApiKey = process.env.CONNECT_BC_TOKEN;

console.log(connUrl, connApiKey);

let url = connUrl + "/api/admin/blc/links?domain=" + domain + "&apikey=" + connApiKey;
console.log(url);

https.get(url, (res) => {
  let body = "";

  res.on("data", (chunk) => {
    body += chunk;
  });

  res.on("end", () => {
    try {
      let json = JSON.parse(body);
      // console.log(json.code);
      if (json.code == 200) {
        links = json.data;
        countMax = links.length;

        links.forEach((el, i) => {
          // console.log(el, i);
          htmlUrlChecker.enqueue(el, {});
        });

        htmlUrlChecker.resume();

        // Mark URLS as checked.
        const data = JSON.stringify({
          domain: domain,
          links: links,
        });

        let post_options = {
          hostname: connHost,
          port: 443,
          path: '/api/admin/blc/process-links',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length,
            'Authorization': 'api-key: ' + connApiKey,
          }
        };

        const req = https.request(post_options, res => {
          // console.log(`statusCode: ${res.statusCode}`)

          res.on('data', d => {
            // process.stdout.write(d)
          })
        });

        req.on('error', error => {
          console.error("Error Posting Links");
          console.error(error);
        });

        req.write(data);
        req.end();
      }
    } catch (error) {
      console.error(error.message);
    };
  });

}).on("error", (error) => {
  console.error(error.message);
});
