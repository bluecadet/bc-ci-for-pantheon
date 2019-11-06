#!/bin/bash

set -eo pipefail

BASE_EXPORT_DIR='accessibility/axe'

# Make artifacts directory
mkdir -p "$ARTIFACTS_FULL_DIR/accessibility"

# Delete if present
if [ -d "$BASE_EXPORT_DIR" ]; then
  rm -rf $BASE_EXPORT_DIR
fi

# Create
echo -e "\nMaking dir $BASE_EXPORT_DIR"
mkdir -p $BASE_EXPORT_DIR

echo -e "\nRunning Report"
axe ${MULTIDEV_SITE_URL} --save "$BASE_EXPORT_DIR/accessibility-report.json"

REPORT_URLS=()
REPORT_URLS+=("$CIRCLE_ARTIFACTS_URL/$BASE_EXPORT_DIR/accessibility-report.json")


echo -e "\nRsyncing files FROM $BASE_EXPORT_DIR to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $BASE_EXPORT_DIR "$ARTIFACTS_FULL_DIR/accessibility"
echo -e "\n"

echo -e "\nRsyncing files FROM $BASE_EXPORT_DIR to workspace dir..."
rsync -rlvz $BASE_EXPORT_DIR /tmp/workspace/accessibility
echo -e "\n"

echo -e ${REPORT_URLS[0]}


AXE_PR_MESSAGE="\n\n## $ICON_REPORT AXE report:\n"

INDEX=0
for i in ${REPORT_URLS[@]}; do
  AXE_PR_MESSAGE="$AXE_PR_MESSAGE [Report $ICON_ARROW](${i})\n"
  let INDEX=${INDEX}+1
done

AXE_PR_MESSAGE="$AXE_PR_MESSAGE \n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)\n\n"

# Set gloabl vars for this job.
AXE_BASH_ENV=${AXE_BASH_ENV:-$HOME/.axebashrc}
(
  echo "export AXE_PR_MESSAGE='$AXE_PR_MESSAGE'"
) >> $AXE_BASH_ENV

echo 'Contents of AXE_BASH_ENV:'
cat $AXE_BASH_ENV
echo

cp $AXE_BASH_ENV  /tmp/workspace/axe_bash_env.txt
