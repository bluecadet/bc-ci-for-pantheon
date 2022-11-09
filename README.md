# bc-ci-for-pantheon

[Refer to doc for similar/old information](https://docs.google.com/document/d/171_g7c6R9N3Ytm71N035jWpwxH05_aCNX7iETMlpub4/edit#heading=h.ndebq7ycxfsh). We'll be updating this readme from now on.

CI scripts for pantheon websites (Drupal and Wordpress) developed by Bluecadet.

Use `cadet` utility to update your CI process. bc-ci-for-pantheon is the Default installer. <br>Commands: `cadet ci-update` or `cadet ci-update --incTestConfig`<br>`cadet ci-update --ci-version 2.1-latest` or `cadet ci-update --ci-version 2.x-latest`

<hr>

## Versions

### 1.x

This version was for Circle CI

### 2.0

This is for Gitrhub Actions, but with Pantheon sites w/out Integrated Composer

### 2.1

This is for Gitrhub Actions, but with Pantheon sites w/ Integrated Composer

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
- IF release branch (persist/***)
  - multidev: `name` (name is first 10 chars of the branch name)
  - Will not clone content
  - Does NOT need a PR open
  - NOTE: must manually delete
- IF pr
  - multidev: `pr-pr##`
  - Will not clone content unless `[clone-content]` is in last git commit message
- IF normal commit
  - Multidev: `ci-###`
  - Will always clone content
  - Currently cancels all jobs... (mimicking build only PRs)

** If we are not on master or default branch we'll load composer dev dependencies and push to pantheon, so we can run all PHPUNIT. We might be able to add more logic to this, b/c that adds a lot of code to add to Pantheon.

### git commit flags:
`[clone-content]`

## Change Log

### 2.0 Branch

- Updates for non-integrated Composer
- Add in yaml processing to figure out PHP version
