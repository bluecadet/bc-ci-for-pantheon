#!/bin/bash

MASTER_PR_MESSAGE="# Build Test Results"

# Code Standards Results
CODER_BASH_ENV=${CODER_BASH_ENV:-$HOME/.coderbashrc}
cp /tmp/workspace/coder_bash_env.txt $CODER_BASH_ENV

source $CODER_BASH_ENV

echo 'Contents of CODER_BASH_ENV:\n'
cat $CODER_BASH_ENV
echo

MASTER_PR_MESSAGE="$MASTER_PR_MESSAGE\n\n---\n\n$CODER_PR_MESSAGE"


# HTML Validator
source /tmp/workspace/bash/html_bash_env.txt
echo 'Contents of CODER_BASH_ENV:\n'
cat /tmp/workspace/bash/html_bash_env.txt
echo

MASTER_PR_MESSAGE="$MASTER_PR_MESSAGE\n\n---\n\n$HTML_PR_MESSAGE"


# PHPUnit results
phpunit_bash_env

PHPUNIT_BASH_ENV=${PHPUNIT_BASH_ENV:-$HOME/.phpunitbashrc}
cp /tmp/workspace/phpunit_bash_env.txt $PHPUNIT_BASH_ENV

source $PHPUNIT_BASH_ENV

echo 'Contents of PHPUNIT_BASH_ENV:\n'
cat $PHPUNIT_BASH_ENV
echo

MASTER_PR_MESSAGE="$MASTER_PR_MESSAGE\n\n---\n\n$PHPUNIT_PR_MESSAGE"


# Visual Regression Results
VR_BASH_ENV=${VR_BASH_ENV:-$HOME/.vrbashrc}
cp /tmp/workspace/vr_bash_env.txt $VR_BASH_ENV

source $VR_BASH_ENV

echo 'Contents of VR_BASH_ENV:\n'
cat $VR_BASH_ENV
echo

MASTER_PR_MESSAGE="$MASTER_PR_MESSAGE\n\n---\n\n$VR_PR_MESSAGE"



# LIGHTHOUSE RESULTS
LIGHTHOUSE_BASH_ENV=${LIGHTHOUSE_BASH_ENV:-$HOME/.lhbashrc}
cp /tmp/workspace/lighthouse_bash_env.txt $LIGHTHOUSE_BASH_ENV

source $LIGHTHOUSE_BASH_ENV

echo 'Contents of LIGHTHOUSE_BASH_ENV:\n'
cat $LIGHTHOUSE_BASH_ENV
echo

MASTER_PR_MESSAGE="$MASTER_PR_MESSAGE\n\n---\n\n$LIGHTHOUSE_PR_MESSAGE"



# Axe Reports
AXE_BASH_ENV=${AXE_BASH_ENV:-$HOME/.axebashrc}
cp /tmp/workspace/axe_bash_env.txt $AXE_BASH_ENV

source $AXE_BASH_ENV

echo 'Contents of AXE_BASH_ENV:\n'
cat $AXE_BASH_ENV
echo

MASTER_PR_MESSAGE="$MASTER_PR_MESSAGE\n\n---\n\n$AXE_PR_MESSAGE"



# Pa11y Reports
PA11Y_BASH_ENV=${PA11Y_BASH_ENV:-$HOME/.pa11ybashrc}
cp /tmp/workspace/pa11y_bash_env.txt $PA11Y_BASH_ENV

source $PA11Y_BASH_ENV

echo 'Contents of PA11Y_BASH_ENV:\n'
cat $PA11Y_BASH_ENV
echo

MASTER_PR_MESSAGE="$MASTER_PR_MESSAGE\n\n---\n\n$PA11Y_PR_MESSAGE"










# Finish up!
echo -e ${MASTER_PR_MESSAGE}
# Save Full message to markdown file.

# Create artifacts directory if it doesn't exist.
echo -e "\nMaking dir $ARTIFACTS_FULL_DIR\n"
mkdir -p $ARTIFACTS_FULL_DIR

echo -e "$MASTER_PR_MESSAGE" > "$ARTIFACTS_FULL_DIR/message.md"
markdown "$ARTIFACTS_FULL_DIR/message.md" --flavor gfm -h true > "$ARTIFACTS_FULL_DIR/message-gfm.html"
markdown "$ARTIFACTS_FULL_DIR/message.md" --flavor markdown -h true > "$ARTIFACTS_FULL_DIR/message-markdown.html"

echo -e "Copying bash files to artifacts dir.\n"
cp /tmp/workspace/bash $ARTIFACTS_FULL_DIR

# Post back to the pull request on GitHub
echo -e "\nPosting results back to PR #$PR_NUMBER "
curl -s -i -u "$CI_PROJECT_USERNAME:$GITHUB_TOKEN" -d "{\"body\": \"$MASTER_PR_MESSAGE\"}" $GITHUB_API_URL/issues/$PR_NUMBER/comments > /dev/null
