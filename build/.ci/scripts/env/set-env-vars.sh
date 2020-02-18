#!/bin/bash
set -eo pipefail

cp /tmp/workspace/bash_env.txt $BASH_ENV

CI_BUILD_NUMBER=${CI_BUILD_NUMBER:-$CIRCLE_BUILD_NUM}

echo "export CI_BUILD_NUMBER='${CI_BUILD_NUMBER}'" >> $BASH_ENV
echo "export CI_BUILD_URL='${CIRCLE_BUILD_URL}'" >> $BASH_ENV
echo "export CI_NODE_INDEX='${CIRCLE_NODE_INDEX}'" >> $BASH_ENV

echo "export CIRCLE_ARTIFACTS_URL='${CIRCLE_BUILD_URL}/artifacts/${CIRCLE_NODE_INDEX}/artifacts'" >> $BASH_ENV

echo 'Setting NODE_PATH'
echo "export NODE_PATH=$(npm root -g)" >> $BASH_ENV

source $BASH_ENV

echo 'Contents of BASH_ENV:'
cat $BASH_ENV
echo

if [ "$SHOULD_BUILD_JOB" = false ] ; then
    echo -e "No need to keep running job."
    circleci-agent step halt
fi
