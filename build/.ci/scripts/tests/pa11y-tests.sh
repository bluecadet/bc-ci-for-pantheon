#!/bin/bash

# set -eo pipefail

BASE_EXPORT_DIR='accessibility/pa11y'

# Make artifacts directory
mkdir -p "$ARTIFACTS_FULL_DIR/accessibility"


# Delete if present
if [ -d "$BASE_EXPORT_DIR" ]; then
  rm -rf $BASE_EXPORT_DIR
fi

# Create.
echo -e "\nMaking dir $BASE_EXPORT_DIR"
mkdir -p $BASE_EXPORT_DIR

REPORT="$BASE_EXPORT_DIR/report.json"

# Check for custom config file
if [ ! -f ./tests/pa11y/.pa11lyci.json ]; then
  # Prepare config file.
  node ./tests/config-gen/build-test-config-files.js --incTest=pa11y
fi

echo -e "\nRunning Report"
pa11y-ci --config=./tests/pa11y/.pa11yci.json --json > ${REPORT}
echo -e "\nConverting to HTML"
pa11y-ci-reporter-html -s ${REPORT} -d "$BASE_EXPORT_DIR/html"

JSON_REPORT_URL="$CIRCLE_ARTIFACTS_URL/$BASE_EXPORT_DIR/report.json"
HTML_REPORT_URL="$CIRCLE_ARTIFACTS_URL/$BASE_EXPORT_DIR/html/index.html"

# Sync files.
echo -e "\nRsyncing files FROM $BASE_EXPORT_DIR to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $BASE_EXPORT_DIR "$ARTIFACTS_FULL_DIR/accessibility"
echo -e "\n"

echo -e ${REPORT_URLS[0]}


# Prepare report.
PA11Y_PR_MESSAGE="\n\n## $ICON_REPORT Pa11y Report:\n"

TOTAL_URLS=$(cat $REPORT | jq '.["total"] | floor | tonumber')
PASSESD_URLS=$(cat $REPORT | jq '.["passes"] | floor | tonumber')
ERRORS=$(cat $REPORT | jq '.["errors"] | floor | tonumber')

PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE|  | SCORE |\n"
PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE| -- | :---: |\n"
PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE| **Total URLS** | \`$TOTAL_URLS\` |\n"
PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE| **Passed URLS** | \`$PASSESD_URLS\` |\n"
PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE| **Errors** | \`$ERRORS\` |\n"

PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE \n\n\n"

PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE [Full Report $ICON_ARROW]($HTML_REPORT_URL)"

PA11Y_PR_MESSAGE="$PA11Y_PR_MESSAGE \n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)\n\n"

# Set gloabl vars for this job.
PA11Y_BASH_ENV=${PA11Y_BASH_ENV:-$HOME/.pa11ybashrc}
(
  echo "export PA11Y_PR_MESSAGE='$PA11Y_PR_MESSAGE'"
) >> $PA11Y_BASH_ENV

echo 'Contents of PA11Y_BASH_ENV:'
cat $PA11Y_BASH_ENV
echo

cp $PA11Y_BASH_ENV  /tmp/workspace/pa11y_bash_env.txt
