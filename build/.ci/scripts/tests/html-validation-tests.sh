#!/bin/bash

# Bail on errors
set -eo pipefail

echo -e "Sourceing funcs"
source .ci/scripts/lib/myFuncs

##
# Setup directories and file variables.
##
echo -e "Setting up variables...\n"

BASE_EXPORT_DIR="/tmp/workspace/html"
HTML_JSON_EXPORT_FILE="html-report.json"
HTML_PRETTY_EXPORT_REPORT="$BASE_EXPORT_DIR/html-report.txt"

CONFIG_FILE="./tests/html-validation/html-config.json"

HTML_REPORT_URL="$CIRCLE_ARTIFACTS_URL/html/html-report.json"

HTML_BASH_ENV="/tmp/workspace/bash/html_bash_env.txt"

# Make worspace directories
echo -e "Make export directory\n"
mkdir -p ${BASE_EXPORT_DIR}

echo -e "Make bash file\n"
mktouch ${HTML_BASH_ENV}







##
# Run tests
##

echo -e "Checking and creating config...\n"
# Check for custom config file.
if [ ! -f ${CONFIG_FILE} ]; then
  # Prepare config file.
  node ./tests/config-gen/build-test-config-files.js --incTest=html
fi

# Run tests
site-validator ${CONFIG_FILE} --verbose --output ${HTML_JSON_EXPORT_FILE:0:-5} > ${HTML_PRETTY_EXPORT_REPORT}

TEST_PASSED=$(cat ${HTML_JSON_EXPORT_FILE} | jq '.passed')
TOTAL_URLS=$(cat ${HTML_JSON_EXPORT_FILE} | jq '.pages | length')
PASSED_URLS=$(cat ${HTML_JSON_EXPORT_FILE} | jq '.results["passed"] | length')
ERRORED_URLS=$(cat ${HTML_JSON_EXPORT_FILE} | jq '.results["failed"] | length')
TOTAL_ERRORS=$(cat ${HTML_JSON_EXPORT_FILE} | jq '[.results["failed"][] | .errors[] ] | length')




##
# Setup PR meassage
##
echo -e "Creating PR message...\n"
HTML_PR_MESSAGE="\n\n## $ICON_REPORT HTML Validation Report:\n"

if [ "$TEST_PASSED" = true ] ; then
  HTML_PR_MESSAGE="$HTML_PR_MESSAGE$ICON_PASSED TEST PASSED\n\n"
else
  HTML_PR_MESSAGE="$HTML_PR_MESSAGE$ICON_FAILED TEST FAILED\n\n"
fi

HTML_PR_MESSAGE="$HTML_PR_MESSAGE\n### LighHTML Validationthouse summary:\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE| | Value |\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE| -- | :---: |\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE| Passed? | ${TEST_PASSED} |\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE| Total Urls | ${TOTAL_URLS} |\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE| Passed Urls | ${PASSED_URLS} |\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE| Errored Urls | ${ERRORED_URLS} |\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE| Total Errors | ${TOTAL_ERRORS} |\n\n"

HTML_PR_MESSAGE="$HTML_PR_MESSAGE[View Report $ICON_ARROW]($HTML_REPORT_URL)\n\n"
HTML_PR_MESSAGE="$HTML_PR_MESSAGE \n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)\n\n"

# Set gloabl vars for this job.
(
  echo "export HTML_PR_MESSAGE='$HTML_PR_MESSAGE'"
) >> $HTML_BASH_ENV

echo 'Contents of BASH_ENV:'
cat $HTML_BASH_ENV
echo





##
# Setup artifacts to save.
##

# Copy everything to artifacts dir.
echo -e "\n Copy JSON report to workspace..."
cp ${HTML_JSON_EXPORT_FILE} ${BASE_EXPORT_DIR}

echo -e "\nRsyncing files to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $BASE_EXPORT_DIR $ARTIFACTS_FULL_DIR
echo -e "\n"


