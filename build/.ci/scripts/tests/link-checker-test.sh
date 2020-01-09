#!/bin/bash

# set -eo pipefail

##
# Setup directories and file variables.
##
echo -e "Setting up variables...\n"

BASE_EXPORT_DIR="/tmp/workspace/blc"

BLC_REPORT_URL_BASE="$CIRCLE_ARTIFACTS_URL/blc"
BLC_REPORT_NAME="blc-result.txt"

BLC_BASH_ENV="/tmp/workspace/bash/blc_bash_env.txt"




# Make worspace directories
echo -e "Make export directory\n"
mkdir -p ${BASE_EXPORT_DIR}







##
# Run tests
##
echo -e "Running test...\n"
blc ${LIVE_SITE_URL} --filter-level 0 -fro > "$BASE_EXPORT_DIR/$BLC_REPORT_NAME"

echo -e "Finished running test...\n"







##
# Setup PR meassage
##
echo -e "Creating PR message...\n"
BLC_PR_MESSAGE="## $ICON_REPORT Broken Link Checker Report:\n\n"
BLC_PR_MESSAGE="$BLC_PR_MESSAGE[View Test]("$BLC_REPORT_URL_BASE/$BLC_REPORT_NAME")\n\n"
BLC_PR_MESSAGE="$BLC_PR_MESSAGE[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)"

echo -e "$BLC_PR_MESSAGE"

# Set gloabl vars for this job.
(
  echo "export BLC_PR_MESSAGE='$BLC_PR_MESSAGE'"
) >> $BLC_BASH_ENV







##
# Setup artifacts to save.
##
echo -e "\nRsyncing files to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $BASE_EXPORT_DIR $ARTIFACTS_FULL_DIR
echo -e "\n"
