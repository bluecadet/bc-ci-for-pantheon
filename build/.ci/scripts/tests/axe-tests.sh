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
# axe ${MULTIDEV_SITE_URL} --save "$BASE_EXPORT_DIR/accessibility-report.json"
# Check for report creator.
if [ -f ./.ci/scripts/tests/axe-report-creator.js ]; then

  echo 'File exists running node script.'
  # Prepare config file.
  node ./.ci/scripts/tests/axe-report-creator.js
fi


# if [ -f ./.axeReportFiles.json ]; then
#   REPORT_URLS=$(cat .axeReportFiles.json | jq -r '.[]')
#   REPORT_NAMES=$(cat .axeReportNames.json | jq -r '.[]')
#   echo -e 'URLS:'
#   echo -e ${REPORT_URLS}
#   echo -e 'NAMES:'
#   echo -e ${REPORT_NAMES}


#   DATA=$(cat .axeReportData.json | jq -r '.names ')
#   echo -e 'DATA1:'
#   echo -e ${DATA1}
#   echo -e ${DATA1[1]}

#   DATA=$(cat .axeReportData.json | jq -r '.names | .[]')
#   echo -e 'DATA2:'
#   echo -e ${DATA1}
#   echo -e ${DATA1[1]}
# fi


echo -e "\nRsyncing files FROM $BASE_EXPORT_DIR to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $BASE_EXPORT_DIR "$ARTIFACTS_FULL_DIR/accessibility"
echo -e "\n"

rsync -rlvz .axeReportFiles.json "$ARTIFACTS_FULL_DIR/accessibility"
rsync -rlvz .axeReportNames.json "$ARTIFACTS_FULL_DIR/accessibility"
rsync -rlvz .axeReportData.json "$ARTIFACTS_FULL_DIR/accessibility"

echo -e "\nRsyncing files FROM $BASE_EXPORT_DIR to workspace dir..."
rsync -rlvz $BASE_EXPORT_DIR /tmp/workspace/accessibility
echo -e "\n"

echo -e ${REPORT_URLS[0]}


AXE_PR_MESSAGE="\n\n## $ICON_REPORT AXE report:\n"

MSG=$(cat .axeReportData.json | jq -r '.msg ')

AXE_PR_MESSAGE="$AXE_PR_MESSAGE $MSG"

# INDEX=1
# for i in ${REPORT_URLS[@]}; do
#   AXE_PR_MESSAGE="$AXE_PR_MESSAGE [Report: ${REPORT_NAMES[$INDEX]} $ICON_ARROW](${i})\n"

#   echo -e "\n\n"
#   echo REPORT_NAMES[INDEX]
#   echo REPORT_NAMES[$INDEX]
#   echo REPORT_NAMES[${INDEX}]
#   echo $REPORT_NAMES[INDEX]
#   echo $REPORT_NAMES[$INDEX]
#   echo $REPORT_NAMES[${INDEX}]
#   echo "$REPORT_NAMES[INDEX]"
#   echo "$REPORT_NAMES[$INDEX]"
#   echo "$REPORT_NAMES[${INDEX}]"
#   echo "${REPORT_NAMES[INDEX]}"
#   echo "${REPORT_NAMES[$INDEX]}"
#   echo "${REPORT_NAMES[${INDEX}]}"
#   echo ${REPORT_NAMES[INDEX]}
#   echo ${REPORT_NAMES[$INDEX]}
#   echo ${REPORT_NAMES[${INDEX}]}

#   let INDEX=${INDEX}+1
# done


# for i in ${REPORT_NAMES[@]}; do
#   echo "${i}"
# done

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

