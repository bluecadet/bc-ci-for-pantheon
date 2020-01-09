#!/bin/bash

set -eo pipefail


echo -e "Sourceing funcs"
source .ci/scripts/lib/myFuncs

##
# Setup directories and file variables.
##
echo -e "Setting up variables...\n"

BASE_EXPORT_DIR="/tmp/workspace/wpt"

CONFIG_FILE="./tests/web-page-test/wpt.json"

WPT_REPORT_URL_BASE="$CIRCLE_ARTIFACTS_URL/wpt"
WPT_REPORT_NAME="wpt-result.json"

WPT_BASH_ENV="/tmp/workspace/bash/wpt_bash_env.txt"

WPT_API_URL="http://www.webpagetest.org/runtest.php"


# Make worspace directories
echo -e "Make export directory\n"
mkdir -p ${BASE_EXPORT_DIR}

echo -e "Make bash file\n"
mktouch ${WPT_BASH_ENV}







##
# Run tests
##

echo -e "Checking and creating config...\n"
# Check for custom config file.
if [ ! -f ${CONFIG_FILE} ]; then
  # Prepare config file.
  node ./tests/config-gen/build-test-config-files.js --incTest=wpt
fi


NUM_OF_REPORTS=$(cat ${CONFIG_FILE} | jq -r '.urls | length')
echo -e "$NUM_OF_REPORTS"

COUNT="$(($NUM_OF_REPORTS - 1))"
echo -e "$COUNT"

# Run tests
for i in $(seq 0 $COUNT);
do
  echo -e "Starting ... $i"

  # Create directory for this url...
  mkdir -p "$BASE_EXPORT_DIR/$i"

  echo -e "Building data\n"

  DATA="k=A.183a6f5eb5cdc3973da0c4fab40e7ced"
  DATA="$DATA&label=$(cat ${CONFIG_FILE} | jq -r --arg I $i '.urls[$I | tonumber].label')"
  DATA="$DATA&url=$(cat ${CONFIG_FILE} | jq -r --arg I $i '.urls[$I | tonumber].url')"
  DATA="$DATA&f=$(cat ${CONFIG_FILE} | jq -r --arg I $i '.urls[$I | tonumber].f')"
  DATA="$DATA&location=$(cat ${CONFIG_FILE} | jq -r --arg I $i '.urls[$I | tonumber].location')"
  DATA="$DATA&video=$(cat ${CONFIG_FILE} | jq -r --arg I $i '.urls[$I | tonumber].video')"
  DATA="$DATA&runs=$(cat ${CONFIG_FILE} | jq -r --arg I $i '.urls[$I | tonumber].runs')"

  echo -e ${DATA}
  echo -e "\n"
  echo -e ${WPT_API_URL}
  echo -e "\n"
  echo -e ${i}
  echo -e "\n"

  # Execute test.
  echo -e "Calling wpt api...\n"
  curl -d "$DATA" -X POST $WPT_API_URL > "$BASE_EXPORT_DIR/$i/$WPT_REPORT_NAME"

done

##
# Setup PR meassage
##
echo -e "Creating PR message...\n"
WPT_PR_MESSAGE="## $ICON_REPORT WebPageTest Report:\n\n"

for i in $(seq 0 $COUNT);
do

  # WPT_URL=$( echo ${RESPONSE} | jq -r '.data.userUrl' )
  WPT_PR_MESSAGE="$WPT_PR_MESSAGE$(cat ${CONFIG_FILE} | jq -r --arg I $i '.urls[$I | tonumber].label')\n"
  WPT_PR_MESSAGE="$WPT_PR_MESSAGE[View Reports]($( cat "$BASE_EXPORT_DIR/$i/$WPT_REPORT_NAME" | jq -r '.data.userUrl' ))\n\n"

done

WPT_PR_MESSAGE="$WPT_PR_MESSAGE\n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)"

echo -e "$WPT_PR_MESSAGE"

# Set global vars for this job.
(
  echo "export WPT_PR_MESSAGE='$WPT_PR_MESSAGE'"
  echo "export WPT_NUM_OF_REPORTS='$NUM_OF_REPORTS'"
) >> $WPT_BASH_ENV





##
# Setup artifacts to save.
##

# Copy everything to artifacts dir.
# echo -e "\nCopy JSON report to workspace..."
# cp ${HTML_JSON_EXPORT_FILE} ${BASE_EXPORT_DIR}

echo -e "\nRsyncing files to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $BASE_EXPORT_DIR $ARTIFACTS_FULL_DIR
echo -e "\n"
