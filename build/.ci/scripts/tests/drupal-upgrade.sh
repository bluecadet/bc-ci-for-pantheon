#!/bin/bash

# Bail on errors
# set -eo pipefail

# Variables
BASH_ENV="/tmp/workspace/bash/upcheck_bash_env.txt"
echo -e "Make bash file\n"
mktouch ${HTML_BASH_ENV}

# Function to check if composer package exists.
drupal_check_exist() {
  composer show | grep mglaman/drupal-check >/dev/null
}

if [ "$CMS_PLATFORM" == "D8" ]; then
  if drupal_check_exist; then
      echo -e 'mglaman/drupal-check installed, continuing'

      # Make artifacts directory
      echo -e "Making artifacts dir"
      mkdir -p $ARTIFACTS_FULL_DIR

      # Set vars
      WORKSPACE_DIR="/tmp/workspace"
      UPCHECK_RESULTS_DIR="$WORKSPACE_DIR/upcheck"
      UPCHECK_MODULE_REPORT_NAME="$UPCHECK_RESULTS_DIR/upcheck-module.json"
      UPCHECK_THEME_REPORT_NAME="$UPCHECK_RESULTS_DIR/upcheck-theme.json"

      # Delete the results directory so we don't keep old results around
      if [ -d "$UPCHECK_RESULTS_DIR" ]; then
        rm -rf $UPCHECK_RESULTS_DIR
      fi

      # Create the results directory if it doesn't exist or has been deleted
      echo -e "Making update dir"
      mkdir -p $UPCHECK_RESULTS_DIR

      # Check Custom modules folder.
      echo -e "Running custom modules test"
      ./vendor/bin/drupal-check -n --no-progress --format=json web/modules/custom > ${UPCHECK_MODULE_REPORT_NAME}
      MODULE_ERRORS=$(cat $UPCHECK_MODULE_REPORT_NAME | jq '.totals.errors')
      MODULE_FILE_ERRORS=$(cat $UPCHECK_MODULE_REPORT_NAME | jq '.totals.file_errors')

      echo -e ${MODULE_ERRORS}
      echo -e ${MODULE_FILE_ERRORS}

      # Check Custom themes folder.
      echo -e "Running custom theme test"
      ./vendor/bin/drupal-check -n --no-progress --format=json web/themes/custom > ${UPCHECK_THEME_REPORT_NAME}
      THEME_ERRORS=$(cat $UPCHECK_THEME_REPORT_NAME | jq '.totals.errors')
      THEME_FILE_ERRORS=$(cat $UPCHECK_THEME_REPORT_NAME | jq '.totals.file_errors')

      echo -e ${THEME_ERRORS}
      echo -e ${THEME_FILE_ERRORS}

      ##
      # Setup PR meassage
      ##
      echo -e "Creating PR message...\n"
      PR_MESSAGE="\n\n## $ICON_REPORT Drupal Upgrade Report:\n"

      # Build Table
      UPCHECK_TABLE="\n### Drupal9 Update summary:\n"
      UPCHECK_TABLE="$UPCHECK_TABLE| Test  | Errors |\n"
      UPCHECK_TABLE="$UPCHECK_TABLE| -- | :---: |\n"
      UPCHECK_TABLE="$UPCHECK_TABLE| Module Errors | \`$MODULE_ERRORS\` |\n"
      UPCHECK_TABLE="$UPCHECK_TABLE| Module File Errors | \`$MODULE_FILE_ERRORS\` |\n"
      UPCHECK_TABLE="$UPCHECK_TABLE| Theme Errors | \`$THEME_ERRORS\` |\n"
      UPCHECK_TABLE="$UPCHECK_TABLE| Theme File Errors | \`$THEME_FILE_ERRORS\` |\n"


      if [ $MODULE_ERRORS -gt 0 ] || [ $MODULE_FILE_ERRORS -gt 0 ] || [ $THEME_ERRORS -gt 0 ] || [ $THEME_FILE_ERRORS -gt 0 ]; then
        PR_MESSAGE="$PR_MESSAGE$ICON_FAILED Drupal9 update returned errors\r\n"
      else
        PR_MESSAGE="$PR_MESSAGE$ICON_FAILED Drupal9 update passed\r\n"
      fi

      PR_MESSAGE="$PR_MESSAGE$UPCHECK_TABLE\n\n"

      MODULE_REPORT_URL="$CIRCLE_ARTIFACTS_URL/upcheck/upcheck-module.json"
      THEME_REPORT_URL="$CIRCLE_ARTIFACTS_URL/upcheck/upcheck-theme.json"

      PR_MESSAGE="$PR_MESSAGE[View Module Report $ICON_ARROW]($MODULE_REPORT_URL)\n\n"
      PR_MESSAGE="$PR_MESSAGE[View Theme Report $ICON_ARROW]($THEME_REPORT_URL)\n\n"
      PR_MESSAGE="$PR_MESSAGE \n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)\n\n"


      # Set gloabl vars for this job.
      (
        echo "export UPCHECK_PR_MESSAGE='$PR_MESSAGE'"
      ) >> $BASH_ENV

      echo -e 'Contents of BASH_ENV:'
      cat $BASH_ENV

      echo -e "\nRsyncing files to $ARTIFACTS_FULL_DIR..."
      rsync -rlvz $UPCHECK_RESULTS_DIR $ARTIFACTS_FULL_DIR
      echo -e "\n"

  else
      echo 'mglaman/drupal-check does not exist.'
      echo 'nothing to check'
  fi
else
  echo 'not running a D8 site. Nothing to test'
fi
