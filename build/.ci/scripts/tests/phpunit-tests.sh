#!/bin/bash

# Make artifacts directory
echo -e "\nMake Workspace Dir."
mkdir -p /tmp/workspace/phpunit

# Make artifacts directory
echo -e "\nMake Artifacts Dir."
mkdir -p "$ARTIFACTS_FULL_DIR/phpunit"



PHPUNIT_PR_MESSAGE="\n\n## $ICON_REPORT PHPUnit report:\n"

if [[ ${CI_BRANCH} == "master" ]] || [[ ${CI_BRANCH} == ${DEFAULT_BRANCH} ]];
then
  echo -e "\nWe are on master or default branch... not running phpunit."

  PHPUNIT_PR_MESSAGE="$PHPUNIT_PR_MESSAGE$ICON_WARNING We are on master or default branch... not running phpunit.\n"
else

  echo -e "\nCalling composer on the pantheon site...."
  terminus -n composer $TERMINUS_SITE.$TERMINUS_ENV -- phpunit-test $MULTIDEV_SITE_URL > /tmp/workspace/phpunit/external_composer_results.txt

  echo -e "\nRsyncing results files to /tmp/artifacts..."
  rsync -rlvz /tmp/workspace/phpunit "$ARTIFACTS_FULL_DIR"
  echo -e "\n"

  REPORT_URL=("$CIRCLE_ARTIFACTS_URL/phpunit/external_composer_results.txt")
  PHPUNIT_PR_MESSAGE="$PHPUNIT_PR_MESSAGE [Report $ICON_ARROW]($REPORT_URL)\n"
fi

# Add job link
PHPUNIT_PR_MESSAGE="$PHPUNIT_PR_MESSAGE \n\n[CircleCI Job $CI_BUILD_NUMBER $ICON_ARROW]($CI_BUILD_URL)\n\n"


# Set gloabl vars for this job.
PHPUNIT_BASH_ENV=${PHPUNIT_BASH_ENV:-$HOME/.phpunitbashrc}
(
  echo "export PHPUNIT_PR_MESSAGE='$PHPUNIT_PR_MESSAGE'"
) >> $PHPUNIT_BASH_ENV

echo 'Contents of PHPUNIT_BASH_ENV:'
cat $PHPUNIT_BASH_ENV
echo

cp $PHPUNIT_BASH_ENV  /tmp/workspace/phpunit_bash_env.txt
