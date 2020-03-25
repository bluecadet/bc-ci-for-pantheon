# bc-ci-for-pantheon

[Refer to doc for similar/old information](https://docs.google.com/document/d/171_g7c6R9N3Ytm71N035jWpwxH05_aCNX7iETMlpub4/edit#heading=h.ndebq7ycxfsh). We'll be updating this readme from now on.

CI scripts for pantheon websites (Drupal and Wordpress) developed by Bluecadet.

Use `cadet` utility to update your CI process. bc-ci-for-pantheon is the Default installer. <br>Commands: `cadet ci-update` or `cadet ci-update --incTestConfig`

<hr>

## Build and deply

__ASSUMPTION:__ We make the assumption that DEV and TEST Pantheon environements will be kept up to date at a certain schedule. This is either done manually or can be run through a cron process. BC's typical dev setup should include this in the normal cron jobs run on the raspi. Default config is to do this every night.

__ASSUMPTION:__ We make the assumption that tests do not fail CI, they only report back their findings. It is up to the dev team to push or not pushed based on the results.

When building and deploying to a new Multi-dev, the content will be copied from the DEV environment. For this to work with the tests properlly, the DEV env should be kept as up to date as possible with LIVE.

Each pipeline will decide which multi-dev env to create based on the structure below:

- IF master branch
  - update DEV env on pantheon
- IF GITHUB Default branch (and not master) -- usually `develop` branch
  - multidev: `default-md`
  - clone content from DEV
- IF release branch (release/***)
  - multidev: `rel-name` (name is first 5 chars of the branch name)
  - Will not clone content unless `[clone-content]` is in last git commit message
- IF pr
  - multidev: `pr-pr##`
  - Will not clone content unless `[clone-content]` is in last git commit message
- IF normal commit
  - Multidev: `ci-###`
  - Will always clone content
  - Currently cancels all jobs... (mimicking build only PRs)

** If we are not on master or default branch we'll load composer dev dependencies and push to pantheon, so we can run all PHPUNIT. We might be able to add more logic to this, b/c that adds a lot of code to add to Pantheon.

<hr>
<br>

## Custom Docker Images repo

https://github.com/bluecadet/docker-build-tools-ci

Which get built on Quay:
https://quay.io/repository/peteinge/build-tools

<hr>
<br>

## Test Descriptions and processes:

### Code Standards: PHP Code Sniff reports

This check code in the custom modules directory and custom theme directory against Drupal and DrupalPractice coding standards.

### Code Standards: HTML Validation

### Code Standards: PHP Unit Tests

These are the built in Drupal Unit, Kernel, and functional tests. Need to continue building this out so we can get a better summary of results.

### Vis-Reg: BackstopJS

Links:
- Site: [BackstopJS](https://garris.github.io/BackstopJS/)

Visual regression tests. Urls defined in .projectconfig.js file in root and built on demand.

TODOs:
- set options for which environment is the base env.

### Performance: Lighhouse

Links:
 - Site: [Lighthouse](https://developers.google.com/web/tools/lighthouse)
 - [CLI options](https://github.com/GoogleChrome/lighthouse#cli-options)

Currently we run tests against the homepage of the LIVE domain and the current multi-dev environment. And we pull out a few metrics to compare against.

TODOs:
- set options for which urls to check
- add options/settings defined in the test directory

### A11y: AXE tests

### A11y: Pa11y tests

<hr>

## Scheduled tests:

### Web Page Test

### Broken Link Checker
