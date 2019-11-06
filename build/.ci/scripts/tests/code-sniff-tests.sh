#!/bin/bash

# Bail on errors
set -eo pipefail

CODER_BASE_EXPORT_DIR='coder/'

# Make artifacts directory
mkdir -p $ARTIFACTS_FULL_DIR

# Delete if present
if [ -d "$CODER_BASE_EXPORT_DIR" ]; then
  rm -rf $CODER_BASE_EXPORT_DIR
fi

# Do not fail on errors and warnings.
./vendor/bin/phpcs --config-set ignore_errors_on_exit 1
./vendor/bin/phpcs --config-set ignore_warnings_on_exit 1

REPORT_URLS=()
REPORT_NAMES=()
REPORT_STATUS=()

# Stash Circle Artifacts URL
echo "Read Composer File"

LENGTH=$(cat composer.json | jq -r '.scripts["code-sniff"] | length')
COUNT="$(($LENGTH-1))"

CODER_PR_MESSAGE="\n\n## $ICON_REPORT PHP Code Sniff Report:\n"

for i in $(seq 0 $COUNT);
do

  echo -e "\nSetting up directory structure."
  DIR_NAME="$i"
  CODER_EXPORT_DIR="$CODER_BASE_EXPORT_DIR$DIR_NAME"
  mkdir -p $CODER_EXPORT_DIR
  echo -e "\nExport directory: $CODER_EXPORT_DIR"

  COMMAND=$(cat composer.json | jq -r --arg I $i '.scripts["code-sniff"][$I | tonumber] | .')
  echo -e "\nRunning command: \n$COMMAND"
  $(cat composer.json | jq -r --arg I $i '.scripts["code-sniff"][$I | tonumber] | .') > "$CODER_EXPORT_DIR/report.txt"

  REPORT_URLS+=("$CIRCLE_ARTIFACTS_URL/coder/$DIR_NAME/report.txt")
  REPORT_NAMES+=($DIR_NAME)


  if [ -s "$CODER_EXPORT_DIR/report.txt" ]
  then
    REPORT_STATUS+="failed"
    CODER_PR_MESSAGE="$CODER_PR_MESSAGE$ICON_FAILED FAILED \`$COMMAND\`\n[View Report $ICON_ARROW]($CIRCLE_ARTIFACTS_URL/coder/$DIR_NAME/report.txt)\n\n"
  else
    REPORT_STATUS+="passed"
    CODER_PR_MESSAGE="$CODER_PR_MESSAGE$ICON_PASSED PASSED \`$COMMAND\`\n\n"
  fi
done

CODER_PR_MESSAGE="$CODER_PR_MESSAGE \n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)\n\n"

#####
# Prepare reports and variables.
#####

# Keep artifacts directory.
echo -e "\nRsyncing Coder files FROM $CODER_BASE_EXPORT_DIR to $ARTIFACTS_FULL_DIR..."
rsync -rlvz $CODER_BASE_EXPORT_DIR "$ARTIFACTS_FULL_DIR/coder"
echo -e "\n"


# Save to workspace directory.
echo -e "\nRsyncing Coder files FROM $CODER_BASE_EXPORT_DIR to /tmp/workspace..."
rsync -rlvz $CODER_BASE_EXPORT_DIR /tmp/workspace/coder
echo -e "\n"

# Set gloabl vars for this job.
CODER_BASH_ENV=${CODER_BASH_ENV:-$HOME/.coderbashrc}
(
  echo "export CODER_PR_MESSAGE='$CODER_PR_MESSAGE'"
) >> $CODER_BASH_ENV

echo 'Contents of BASH_ENV:'
cat $CODER_BASH_ENV
echo

cp $CODER_BASH_ENV  /tmp/workspace/coder_bash_env.txt
