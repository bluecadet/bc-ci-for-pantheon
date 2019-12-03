#!/bin/bash

source "/tmp/workspace/bash/wpt_bash_env.txt"
source "/tmp/workspace/bash/blc_bash_env.txt"

# Setup Issue Params
TITLE="Scheduled Automated Test Results: $(date '+%Y-%m-%d')"
MESSAGE="# Scheduled Tasks report\n\n"
MESSAGE="$MESSAGE$WPT_PR_MESSAGE\n\n---\n\n$BLC_PR_MESSAGE"

# Post back to GitHub, by creating a new Issue.
echo -e "\nPosting results back to to repo issue."
curl -s -i -u "$CI_PROJECT_USERNAME:$GITHUB_TOKEN" -d "{\"title\": \"$TITLE\", \"body\": \"$MESSAGE\"}" $GITHUB_API_URL/issues > /dev/null
