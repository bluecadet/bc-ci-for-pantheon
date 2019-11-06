#!/bin/bash

# Bail on errors
set -eo pipefail

# Check if we are NOT on the master branch and this is a PR
# if [[ ${CI_BRANCH} != "master" && -z ${CI_PR_URL} ]];
# then
#   echo -e "\nLighthouse tests will only run if we are not on the master branch and making a pull request"
#   exit 0;
# fi

# Variables
BUILD_DIR=$(pwd)
GITHUB_API_URL="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"

# Make artifacts directory
mkdir -p $ARTIFACTS_FULL_DIR

# Set Lighthouse results directory, branch and url
LIGHTHOUSE_BRANCH=$DEFAULT_ENV
LIGHTHOUSE_URL=$MULTIDEV_SITE_URL
LIGHTHOUSE_RESULTS_DIR="lighthouse_results/$LIGHTHOUSE_BRANCH"
LIGHTHOUSE_REPORT_NAME="$LIGHTHOUSE_RESULTS_DIR/lighthouse.json"
LIGHTHOUSE_JSON_REPORT="$LIGHTHOUSE_RESULTS_DIR/lighthouse.report.json"
LIGHTHOUSE_HTML_REPORT="$LIGHTHOUSE_RESULTS_DIR/lighthouse.report.html"
LIGHTHOUSE_RESULTS_JSON="$LIGHTHOUSE_RESULTS_DIR/lighthouse.results.json"
LIGHTHOUSE_SUMMARY_JSON="$LIGHTHOUSE_RESULTS_DIR/lighthouse.summary.json"

# Delete the Lighthouse results directory so we don't keep old results around
if [ -d "$LIGHTHOUSE_RESULTS_DIR" ]; then
  rm -rf $LIGHTHOUSE_RESULTS_DIR
fi

# Create the Lighthouse results directory if it doesn't exist or has been deleted
mkdir -p $LIGHTHOUSE_RESULTS_DIR

# Create the Lighthouse results directory for master if needed
if [ ! -d "lighthouse_results/master" ]; then
	mkdir -p "lighthouse_results/master"
fi

# Ping the Pantheon environment to wake it from sleep and prime the cache
echo -e "\nPinging the ${LIGHTHOUSE_BRANCH} environment to wake it from sleep..."
curl -s -I "$LIGHTHOUSE_URL" >/dev/null

# Run the Lighthouse test
lighthouse --save-artifacts --output json --output html --output-path ${LIGHTHOUSE_REPORT_NAME} --chrome-flags="--headless --disable-gpu --no-sandbox" ${LIGHTHOUSE_URL}

# Check for HTML report file
if [ ! -f $LIGHTHOUSE_HTML_REPORT ]; then
	echo -e "\nLighthouse HTML report file $LIGHTHOUSE_HTML_REPORT not found!"
	exit 1
fi

# Check for JSON report file
if [ ! -f $LIGHTHOUSE_JSON_REPORT ]; then
	echo -e "\nLighthouse JSON report file $LIGHTHOUSE_JSON_REPORT not found!"
	exit 1
fi

# Create tailored results JSON file
cat $LIGHTHOUSE_JSON_REPORT | jq '. | { "total-score": .score, "speed-index": .audits["speed-index-metric"]["score"], "first-meaningful-paint": .audits["first-meaningful-paint"]["score"], "estimated-input-latency": .audits["estimated-input-latency"]["score"], "time-to-first-byte": .audits["time-to-first-byte"]["rawValue"], "first-interactive": .audits["first-interactive"]["score"], "consistently-interactive": .audits["consistently-interactive"]["score"], "critical-request-chains": .audits["critical-request-chains"]["displayValue"], "redirects": .audits["redirects"]["score"], "bootup-time": .audits["bootup-time"]["rawValue"], "uses-long-cache-ttl": .audits["uses-long-cache-ttl"]["score"], "total-byte-weight": .audits["total-byte-weight"]["score"], "offscreen-images": .audits["offscreen-images"]["score"], "uses-webp-images": .audits["uses-webp-images"]["score"], "uses-optimized-images": .audits["uses-optimized-images"]["score"], "uses-request-compression": .audits["uses-request-compression"]["score"], "uses-responsive-images": .audits["uses-responsive-images"]["score"], "dom-size": .audits["dom-size"]["score"], "script-blocking-first-paint": .audits["script-blocking-first-paint"]["score"] }' > $LIGHTHOUSE_RESULTS_JSON
cat $LIGHTHOUSE_JSON_REPORT | jq '[.reportCategories[] | {(.id): .score } ] | add' > $LIGHTHOUSE_SUMMARY_JSON

LIGHTHOUSE_SCORE=$(cat $LIGHTHOUSE_RESULTS_JSON | jq '.["total-score"] | floor | tonumber')
LIGHTHOUSE_HTML_REPORT_URL="$CIRCLE_ARTIFACTS_URL/lighthouse/$LIGHTHOUSE_HTML_REPORT"

LIGHTHOUSE_PRODUCTION_RESULTS_DIR="lighthouse_results/master"
LIGHTHOUSE_PRODUCTION_REPORT_NAME="$LIGHTHOUSE_PRODUCTION_RESULTS_DIR/lighthouse.json"
LIGHTHOUSE_PRODUCTION_JSON_REPORT="$LIGHTHOUSE_PRODUCTION_RESULTS_DIR/lighthouse.report.json"
LIGHTHOUSE_PRODUCTION_HTML_REPORT="$LIGHTHOUSE_PRODUCTION_RESULTS_DIR/lighthouse.report.html"
LIGHTHOUSE_PRODUCTION_RESULTS_JSON="$LIGHTHOUSE_PRODUCTION_RESULTS_DIR/lighthouse.results.json"
LIGHTHOUSE_PRODUCTION_SUMMARY_JSON="$LIGHTHOUSE_PRODUCTION_RESULTS_DIR/lighthouse.summary.json"

# Ping the live environment to wake it from sleep and prime the cache
echo -e "\nPinging the live environment to wake it from sleep..."
curl -s -I "$LIVE_SITE_URL" >/dev/null

# Run Lighthouse on the live environment
echo -e "\nRunning Lighthouse on the live environment"
lighthouse --save-artifacts --output json --output html --output-path "$LIGHTHOUSE_PRODUCTION_REPORT_NAME" --chrome-flags="--headless --disable-gpu --no-sandbox" ${LIVE_SITE_URL}

# Create tailored results JSON file
cat $LIGHTHOUSE_PRODUCTION_JSON_REPORT | jq '. | { "total-score": .score, "speed-index": .audits["speed-index-metric"]["score"], "first-meaningful-paint": .audits["first-meaningful-paint"]["score"], "estimated-input-latency": .audits["estimated-input-latency"]["score"], "time-to-first-byte": .audits["time-to-first-byte"]["rawValue"], "first-interactive": .audits["first-interactive"]["score"], "consistently-interactive": .audits["consistently-interactive"]["score"], "critical-request-chains": .audits["critical-request-chains"]["displayValue"], "redirects": .audits["redirects"]["score"], "bootup-time": .audits["bootup-time"]["rawValue"], "uses-long-cache-ttl": .audits["uses-long-cache-ttl"]["score"], "total-byte-weight": .audits["total-byte-weight"]["score"], "offscreen-images": .audits["offscreen-images"]["score"], "uses-webp-images": .audits["uses-webp-images"]["score"], "uses-optimized-images": .audits["uses-optimized-images"]["score"], "uses-request-compression": .audits["uses-request-compression"]["score"], "uses-responsive-images": .audits["uses-responsive-images"]["score"], "dom-size": .audits["dom-size"]["score"], "script-blocking-first-paint": .audits["script-blocking-first-paint"]["score"] }' > $LIGHTHOUSE_PRODUCTION_RESULTS_JSON
cat $LIGHTHOUSE_PRODUCTION_JSON_REPORT | jq '[.reportCategories[] | {(.id): .score } ] | add' > $LIGHTHOUSE_PRODUCTION_SUMMARY_JSON

LIGHTHOUSE_PRODUCTION_SCORE=$(cat $LIGHTHOUSE_PRODUCTION_RESULTS_JSON | jq '.["total-score"] | floor | tonumber')
LIGHTHOUSE_PRODUCTION_HTML_REPORT_URL="$CIRCLE_ARTIFACTS_URL/lighthouse/$LIGHTHOUSE_PRODUCTION_HTML_REPORT"

# Save to workspace directory.
echo -e "\nRsyncing lighthouse_results files to /tmp/workspace..."
rsync -rlvz lighthouse_results /tmp/workspace/lighthouse

echo -e "\nRsyncing lighthouse_results files to /tmp/artifacts..."
rsync -rlvz lighthouse_results /tmp/artifacts/lighthouse
echo -e "\n"

echo -e "\nMaster score of $LIGHTHOUSE_PRODUCTION_SCORE recorded"


# Level of tolerance for score decline
LIGHTHOUSE_ACCEPTABLE_THRESHOLD=5
LIGHTHOUSE_ACCEPTABLE_SCORE=$((LIGHTHOUSE_PRODUCTION_SCORE-LIGHTHOUSE_ACCEPTABLE_THRESHOLD))

REPORTSLINES="\n### Lighthouse summary:\n"
REPORTSLINES="$REPORTSLINES| Category  | LIVE | $DEFAULT_ENV |\n"
REPORTSLINES="$REPORTSLINES| -- | :---: | :---: |\n"
REPORTSLINES="$REPORTSLINES| Total | \`$LIGHTHOUSE_PRODUCTION_SCORE\` | \`$LIGHTHOUSE_SCORE\` |\n"
REPORTSLINES="$REPORTSLINES| **Performance:** | \`$(cat $LIGHTHOUSE_PRODUCTION_SUMMARY_JSON | jq '.["performance"] | floor | tonumber')\` | \`$(cat $LIGHTHOUSE_SUMMARY_JSON | jq '.["performance"] | floor | tonumber')\` |\n"
REPORTSLINES="$REPORTSLINES| **PWA:** | \`$(cat $LIGHTHOUSE_PRODUCTION_SUMMARY_JSON | jq '.["pwa"] | floor | tonumber')\` | \`$(cat $LIGHTHOUSE_SUMMARY_JSON | jq '.["pwa"] | floor | tonumber')\` |\n"
REPORTSLINES="$REPORTSLINES| **Accessibility:** | \`$(cat $LIGHTHOUSE_PRODUCTION_SUMMARY_JSON | jq '.["accessibility"] | floor | tonumber')\` | \`$(cat $LIGHTHOUSE_SUMMARY_JSON | jq '.["accessibility"] | floor | tonumber')\` |\n"
REPORTSLINES="$REPORTSLINES| **Best Practices:** | \`$(cat $LIGHTHOUSE_PRODUCTION_SUMMARY_JSON | jq '.["best-practices"] | floor | tonumber')\` | \`$(cat $LIGHTHOUSE_SUMMARY_JSON | jq '.["best-practices"] | floor | tonumber')\` |\n"
REPORTSLINES="$REPORTSLINES| **SEO:** | \`$(cat $LIGHTHOUSE_PRODUCTION_SUMMARY_JSON | jq '.["seo"] | floor | tonumber')\` | \`$(cat $LIGHTHOUSE_SUMMARY_JSON | jq '.["seo"] | floor | tonumber')\` |\n"


LIGHTHOUSE_PR_MESSAGE="## $ICON_REPORT Lighthouse Results\n\n"
if [ $LIGHTHOUSE_SCORE -lt $LIGHTHOUSE_ACCEPTABLE_SCORE ]; then
	# Lighthouse test failed! The score is less than the acceptable score
	echo -e "\nAuto update Lighthouse test failed for $CI_PROJECT_REPONAME! The score of $LIGHTHOUSE_SCORE is less than the acceptable score of $LIGHTHOUSE_ACCEPTABLE_SCORE."
	LIGHTHOUSE_PR_MESSAGE="$LIGHTHOUSE_PR_MESSAGE$ICON_FAILED Lighthouse test failed for $CI_PROJECT_REPONAME!\nThe score of \`$LIGHTHOUSE_SCORE\` is less than the acceptable score of \`$LIGHTHOUSE_ACCEPTABLE_SCORE\`.\n\n[View the $CI_PROJECT_REPONAME report $ICON_ARROW]($LIGHTHOUSE_HTML_REPORT_URL)\n[View the LIVE report $ICON_ARROW]($LIGHTHOUSE_PRODUCTION_HTML_REPORT_URL) $REPORTSLINES"
else
	# Lighthouse test passed! The score isn't less than the acceptable score
	echo -e "\nAuto update Lighthouse test passed for $CI_PROJECT_REPONAME! The score of $LIGHTHOUSE_SCORE isn't less than the acceptable score of $LIGHTHOUSE_ACCEPTABLE_SCORE ($LIGHTHOUSE_ACCEPTABLE_THRESHOLD less than the score of $LIGHTHOUSE_PRODUCTION_SCORE on $LIVE_SITE_URL)"
	LIGHTHOUSE_PR_MESSAGE="$LIGHTHOUSE_PR_MESSAGE$ICON_PASSED Lighthouse test passed for $CI_PROJECT_REPONAME!\nThe score of \`$LIGHTHOUSE_SCORE\` is better than the acceptable score of \`$LIGHTHOUSE_ACCEPTABLE_SCORE\`.\n\n[View the $CI_PROJECT_REPONAME report $ICON_ARROW]($LIGHTHOUSE_HTML_REPORT_URL)\n[View the LIVE report $ICON_ARROW]($LIGHTHOUSE_PRODUCTION_HTML_REPORT_URL) $REPORTSLINES"
fi

LIGHTHOUSE_PR_MESSAGE="$LIGHTHOUSE_PR_MESSAGE \n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)\n\n"

# Set gloabl vars for this job.
LIGHTHOUSE_BASH_ENV=${LIGHTHOUSE_BASH_ENV:-$HOME/.lhbashrc}
(
  echo "export LIGHTHOUSE_BRANCH='$LIGHTHOUSE_BRANCH'"
  echo "export LIGHTHOUSE_URL='$LIGHTHOUSE_URL'"
  echo "export LIGHTHOUSE_RESULTS_DIR='$LIGHTHOUSE_RESULTS_DIR'"
  echo "export LIGHTHOUSE_REPORT_NAME='$LIGHTHOUSE_REPORT_NAME'"
  echo "export LIGHTHOUSE_JSON_REPORT='$LIGHTHOUSE_JSON_REPORT'"
  echo "export LIGHTHOUSE_HTML_REPORT='$LIGHTHOUSE_HTML_REPORT'"
  echo "export LIGHTHOUSE_RESULTS_JSON='$LIGHTHOUSE_RESULTS_JSON'"
  echo "export LIGHTHOUSE_SUMMARY_JSON='$LIGHTHOUSE_SUMMARY_JSON'"
  echo "export LIGHTHOUSE_SCORE='$LIGHTHOUSE_SCORE'"
  echo "export LIGHTHOUSE_HTML_REPORT_URL='$LIGHTHOUSE_HTML_REPORT_URL'"
  echo "export LIGHTHOUSE_PRODUCTION_RESULTS_DIR='$LIGHTHOUSE_PRODUCTION_RESULTS_DIR'"
  echo "export LIGHTHOUSE_PRODUCTION_REPORT_NAME='$LIGHTHOUSE_PRODUCTION_REPORT_NAME'"
  echo "export LIGHTHOUSE_PRODUCTION_JSON_REPORT='$LIGHTHOUSE_PRODUCTION_JSON_REPORT'"
  echo "export LIGHTHOUSE_PRODUCTION_HTML_REPORT='$LIGHTHOUSE_PRODUCTION_HTML_REPORT'"
  echo "export LIGHTHOUSE_PRODUCTION_RESULTS_JSON='$LIGHTHOUSE_PRODUCTION_RESULTS_JSON'"
  echo "export LIGHTHOUSE_PRODUCTION_SUMMARY_JSON='$LIGHTHOUSE_PRODUCTION_SUMMARY_JSON'"
  echo "export LIGHTHOUSE_PRODUCTION_SCORE='$LIGHTHOUSE_PRODUCTION_SCORE'"
  echo "export LIGHTHOUSE_PRODUCTION_HTML_REPORT_URL='$LIGHTHOUSE_PRODUCTION_HTML_REPORT_URL'"
  echo "export LIGHTHOUSE_ACCEPTABLE_THRESHOLD='$LIGHTHOUSE_ACCEPTABLE_THRESHOLD'"
  echo "export LIGHTHOUSE_ACCEPTABLE_SCORE='$LIGHTHOUSE_ACCEPTABLE_SCORE'"
  echo "export LIGHTHOUSE_PR_MESSAGE='$LIGHTHOUSE_PR_MESSAGE'"
) >> $LIGHTHOUSE_BASH_ENV

cp $LIGHTHOUSE_BASH_ENV  /tmp/workspace/lighthouse_bash_env.txt
