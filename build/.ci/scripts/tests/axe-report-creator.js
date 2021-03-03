var fs = require('fs');
var { createHtmlReport } = require('axe-html-reporter');
const { spawnSync } = require('child_process');

var rootPath = process.cwd();


const CONFIG = require('../../../.projectconfig.js');
const TEST_URLS_DATA = CONFIG.testingPaths;

var multidevURL = process.env.MULTIDEV_SITE_URL.replace(/\/$/, "");

var reportUrls = [];
var reportNames = [];

let CIRCLE_ARTIFACTS_URL = process.env.CIRCLE_ARTIFACTS_URL;

let reportMsg = "";

TEST_URLS_DATA.forEach(function (el, i) {
  let url = multidevURL + "/" + el.path;
  let jsonReport = "accessibility/axe/accessibility-report." + i + ".json";
  let jsonReportFull = rootPath + '/' + jsonReport;
  let htmlReport = "accessibility-report." + i + ".html";


  const axeRun = spawnSync('axe', [url, '--save', jsonReport], {
    cwd: process.cwd(),
    env: process.env,
    stdio: [process.stdin, process.stdout, process.stderr],
    encoding: 'utf-8'
  });

  let rawdata = fs.readFileSync(jsonReportFull);
  let results = JSON.parse(rawdata);

  createHtmlReport({
    results: results[0],
    options: {
      outputDir: 'accessibility/axe',
      reportFileName: htmlReport,
    },
  });

  let status = {
    critical: 0,
    serious: 0,
    moderate: 0,
    minor: 0,
  };

  results[0].violations.forEach(function (el, j) {
    status[el.impact]++;
  });

  reportUrls.push(CIRCLE_ARTIFACTS_URL + "/accessibility/axe/" + htmlReport);
  reportNames.push(el.label);

  reportMsg += "[Report: " + el.label + " &#10148;](" + CIRCLE_ARTIFACTS_URL + "/accessibility/axe/" + htmlReport + ")\n";
  reportMsg += "Critical: " + status.critical;
  if (status.critical >= 1) reportMsg += " :bangbang: ";
  reportMsg += " -- Serious: " + status.serious;
  if (status.serious >= 1) reportMsg += " :heavy_exclamation_mark: ";
  reportMsg += " -- Moderate: " + status.moderate;
  if (status.moderate >= 1) reportMsg += " :warning: ";
  reportMsg += " -- Minor: " + status.minor;
  if (status.minor >= 1) reportMsg += " :eyes: ";
  reportMsg += "\n\n";
});

let dataToWrite = {};

dataToWrite.urls = reportUrls;
dataToWrite.names = reportNames;
dataToWrite.msg = reportMsg;

fs.writeFileSync(rootPath + '/.axeReportFiles.json', JSON.stringify(reportUrls, null, 2));
fs.writeFileSync(rootPath + '/.axeReportNames.json', JSON.stringify(reportNames, null, 2));
fs.writeFileSync(rootPath + '/.axeReportData.json', JSON.stringify(dataToWrite, null, 2));
