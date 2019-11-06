#!/bin/bash

echo "You provided the arguments:" "$@"

echo "First Arg: " "$0"
echo "Second Arg: " "$1"


# Make sure simpletest module is enabled.
drush en simpletest

# Run PHPUnit Tests the Drupal Way.
php web/core/scripts/run-tests.sh --url $1  --directory modules/custom --verbose --non-html
