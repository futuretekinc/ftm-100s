#!/bin/sh

FOREVER=`which forever`
if [ -n "$FOREVER" ] ; then
  $FOREVER restart device &
else
  echo "Error: failure to restart"
  exit 1;
fi
