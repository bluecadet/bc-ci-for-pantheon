#!/bin/bash

set -eo pipefail

# include common funcs
. ./.ci/scripts/lib/myFuncs


echo "Prepring build for $TERMINUS_ENV. Pantheon test environment is $TERMINUS_SITE.$TERMINUS_ENV\n"

# Report installed version of Terminus
terminus --version

# Delete leftover CI environments
terminus -n build:env:delete:ci "$TERMINUS_SITE" --keep=2 --yes
echo -e "Finished checking CI environments\n"

# Delete leftover PR environments
terminus -n build:env:delete:pr "$TERMINUS_SITE" --yes
echo -e "Finished checking PR environments\n"

# Delete leftover REL environments
deleteReleaseEnvs
echo -e "Finished checking Release environments\n"



if [[ ${CI_BRANCH} == "master" ]] || [[ ${CI_BRANCH} == ${DEFAULT_BRANCH} ]];
then
  echo -e "\nRunning composer build-assets to get production assets assets.\n"
  composer -n build-assets
else
  echo -e "\nRunning composer install to get all assets.\n"
  composer -n install
fi

echo -e "Finished composer install\n"
