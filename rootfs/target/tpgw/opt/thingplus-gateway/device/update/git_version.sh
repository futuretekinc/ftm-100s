#!/bin/sh

CUR_DIR=`dirname "$0"`

GIT_AVAILE=0
which git > /dev/null || GIT_AVAILE=$?

if [ $GIT_AVAILE -eq 0 ]; then
  cd $CUR_DIR
  echo @@local
  git log --pretty="%h%n%ai%n%s" -1 || exit 1;
  echo @@remote
  git ls-remote -h origin refs/heads/`git rev-parse --abbrev-ref HEAD` | head -c7
  exit $?
fi
