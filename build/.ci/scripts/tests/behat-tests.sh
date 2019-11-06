#!/bin/bash

# if [[ ${CI_BRANCH} != "master" && -z ${PR_NUMBER} ]];
# then
#   echo -e "CI will only deploy to Pantheon if on the master branch or creating a pull requests.\n"
#   exit 0;
# fi

# Bail if required environment varaibles are missing
if [ -z "$TERMINUS_SITE" ] || [ -z "$TERMINUS_ENV" ]
then
  echo 'No test site specified. Set TERMINUS_SITE and TERMINUS_ENV.'
  exit 1
fi

echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo "Behat test site: $TERMINUS_SITE.$TERMINUS_ENV"
echo "::::::::::::::::::::::::::::::::::::::::::::::::"
echo

# Clear site cache
terminus -n env:clear-cache $TERMINUS_SITE.$TERMINUS_ENV

# Wake the multidev environment before running tests
terminus -n env:wake $TERMINUS_SITE.$TERMINUS_ENV

# Ping drush to start ssh with the app server
terminus -n drush $TERMINUS_SITE.$TERMINUS_ENV -- version

# Verbose mode and exit on errors
set -ex

# Create a drush alias file so that Behat tests can be executed against Pantheon.
terminus alpha:aliases --no-db-url --only=$TERMINUS_SITE
drush sa @pantheon.$TERMINUS_SITE.$TERMINUS_ENV

# Drush Behat driver fails without this option.
echo "\$options['strict'] = 0;" >> ~/.drush/pantheon.aliases.drushrc.php

SELF_DIRNAME="`dirname -- "$0"`"
$SELF_DIRNAME/run-behat-ci
