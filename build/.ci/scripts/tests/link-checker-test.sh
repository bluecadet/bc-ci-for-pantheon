#!/bin/bash

# set -eo pipefail

##
# Setup directories and file variables.
##
echo -e "Setting up variables...\n"

ARTIFACTS_URL_BASE="$CIRCLE_ARTIFACTS_URL/blc"

BASE_EXPORT_DIR="/tmp/workspace/blc"

BLC_REPORT_NAME="blc-result.txt"
BLC_REPORT="$BASE_EXPORT_DIR/$BLC_REPORT_NAME"

# BLC_BASH_ENV="/tmp/workspace/bash/blc_bash_env.txt"

echo -e "Make bash directory\n"
mkdir -p /tmp/workspace/bash



# Make worspace directories
echo -e "Make export directory\n"
mkdir -p ${BASE_EXPORT_DIR}





##
# Run tests
##
echo -e "Running test...\n"
# blc ${LIVE_SITE_URL} --filter-level 0 -fro > "$BASE_EXPORT_DIR/$BLC_REPORT_NAME"
node ./.ci/scripts/tests/blc.js ${LIVE_SITE_URL} ${BASE_EXPORT_DIR} ${BLC_REPORT_NAME}
echo -e "Finished running test...\n"

REPORT_MSG=$(cat $BLC_REPORT | jq -r '.["msg"]')
ERROR_COUNT=$(cat $BLC_REPORT | jq '.["errorCount"] | tonumber')

echo -e "$REPORT_MSG"
echo -e "$ERROR_COUNT"



##
# Setup PR meassage
##
echo -e "Creating PR message...\n"
BLC_PR_MESSAGE="## $ICON_REPORT Broken Link Checker Report:\n\n"
BLC_PR_MESSAGE+="Message: $REPORT_MSG\n"
BLC_PR_MESSAGE+="Errors: $ERROR_COUNT\n\n"
BLC_PR_MESSAGE="$BLC_PR_MESSAGE[View Test]("$ARTIFACTS_URL_BASE/$BLC_REPORT_NAME")\n\n"
BLC_PR_MESSAGE="$BLC_PR_MESSAGE[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)"

echo -e "$BLC_PR_MESSAGE"

# Set gloabl vars for this job.
BLC_BASH_ENV=${BLC_BASH_ENV:-$HOME/.blcbashrc}
(
  echo "export BLC_PR_MESSAGE='$BLC_PR_MESSAGE'"
) >> $BLC_BASH_ENV

cp $BLC_BASH_ENV  /tmp/workspace/bash/blc_bash_env.txt
cp $BLC_BASH_ENV  /tmp/workspace/blc/blc_bash_env.txt





##
# Setup artifacts to save.
##
echo -e "\nRsyncing files to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $BASE_EXPORT_DIR $ARTIFACTS_FULL_DIR
echo -e "\n"
