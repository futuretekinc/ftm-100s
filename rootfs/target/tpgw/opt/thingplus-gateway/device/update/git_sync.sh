#!/bin/sh

CUR_DIR=`dirname "$0"`

#check git
GIT_AVAILE=0
which git > /dev/null || GIT_AVAILE=$?

if [ $GIT_AVAILE -ne 0 ]; then
  echo "[gitsync.sh] git not found"
  exit 1;
fi

#cd to git top dir
cd `git rev-parse --show-toplevel`

#reset to latest version, unracked files are preserved.
git fetch && git reset --hard origin/`git rev-parse --abbrev-ref HEAD`
rc=$?
if [ $rc != "0"  ] ; then
  echo "[gitsync.sh] fail to git fetch and reset"
  exit $rc
fi
