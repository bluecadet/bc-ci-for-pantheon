#!/bin/bash

# source "/tmp/workspace/bash/wpt_bash_env.txt"
# source "/tmp/workspace/bash/blc_bash_env.txt"

# Setup Issue Params
TITLE="Scheduled Automated Test Results $CIRCLE_BUILD_NUM: $(date '+%Y-%m-%d')"
MESSAGE="# Scheduled Tasks report\n\n"
# MESSAGE="$MESSAGE$WPT_PR_MESSAGE\n\n---\n\n$BLC_PR_MESSAGE"

# Web Page Test Messages.
WPT_BASH_ENV=${WPT_BASH_ENV:-$HOME/.blcbashrc}
cp /tmp/workspace/bash/wpt_bash_env.txt $WPT_BASH_ENV
source $WPT_BASH_ENV
MESSAGE="$MESSAGE\n\n---\n\n$WPT_PR_MESSAGE"


# Broken Link checker Messages.
BLC_BASH_ENV=${BLC_BASH_ENV:-$HOME/.blcbashrc}
cp /tmp/workspace/bash/blc_bash_env.txt $BLC_BASH_ENV
source $BLC_BASH_ENV
MESSAGE="$MESSAGE\n\n---\n\n$BLC_PR_MESSAGE"

# Post back to GitHub, by creating a new Issue.
echo -e "\nPosting results back to to repo issue."
curl -s -i -u "$CI_PROJECT_USERNAME:$GITHUB_TOKEN" -d "{\"title\": \"$TITLE\", \"body\": \"$MESSAGE\"}" $GITHUB_API_URL/issues
