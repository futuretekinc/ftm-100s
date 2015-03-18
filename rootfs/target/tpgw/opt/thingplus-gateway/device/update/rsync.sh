#!/bin/sh

CUR_DIR=`dirname "$0"`
. $CUR_DIR/models.sh

#options
OPT_HELP=0
OPT_GET_VERSION=0
OPT_RECOVER=0
OPT_CHECK_VERSION=0
OPT_PASSWORD=
OPT_SIZE_ONLY=0

GETOPT=`getopt -o hvrscp: --long help,get-version,recover,size-only,check-version,password: \
  -n "$0" -- "$@"`

show_help() {
  echo "Usage: $0 source_url destination_directory"
  echo "	-v, --get-version: get remote version only" 
  echo "	-r, --recover: do sync only when previous try was not compelte" 
  echo "	-s, --size-only: rsync size only options" 
  echo "	-c, --check-version: do not sync if versions are same"
  echo "	-p, psswored"
}

eval set -- "$GETOPT"
while true ; do
  case $1 in
    -h|--help) OPT_HELP=1; shift ;;
    -v|--get-version) OPT_GET_VERSION=1; shift ;;
    -s|--size-only) OPT_SIZE_ONLY=1; shift ;;
    -r|--recover) OPT_RECOVER=1; shift ;;
    -p|--password) OPT_PASSWORD="$2"; shift 2 ;;
    -c|--check-version) OPT_CHECK_VERSION=1; shift ;;
    --) shift; break ;;
    *) echo "error\n"; show_help; ;;
  esac
done
SRC_URL=$1 
DST_DIR="$CUR_DIR/../.."

if [ -z "$SRC_URL" -o -z "$DST_DIR" ]; then
  echo "missing params";
  show_help;
  exit 1;
fi

RSYNC=`which rsync`
if [ -z "$RSYNC" ]; then
  echo "Error: rsync not found"; exit 1;
fi
STUNNEL=`which stunnel`
STUNNEL4=`which stunnel4`
if [ -n "$STUNNEL" -o -n "$STUNNEL4" ]; then
  STUNNEL_OPT="--rsh=$CUR_DIR/rsync-ssl-stunnel"
else
    #echo "Error: stunnel not found"; exit 1;
    #FIXME:
    echo "[rsync.sh] Warning: stunnel not found"; 
fi

SRC_VERSION_FILE="$SRC_URL/VERSION"
DST_VERSION_FILE="$DST_DIR/VERSION"
DST_REMOTE_VERSION_FILE="$DST_DIR/REMOTE_VERSION"
INPROGRESS_FILE="$DST_DIR/_rsync_in_progress"

if [ -f $CUR_DIR/rsync_filter.txt ]; then
  FILTER_OPTION="-f"
  FILTER_FILE_OPTION="merge $CUR_DIR/rsync_filter.txt"
else 
  echo "MODEL:$MODEL $CUR_DIR/rsync_filter.txt not found"
  exit 1;
fi

get_version() {
  RSYNC_PASSWORD=$OPT_PASSWORD \
  $RSYNC -z \
  $SRC_VERSION_FILE $DST_REMOTE_VERSION_FILE
  return $?
}

chk_version() {
  rc=0
  get_version || rc=$?
  if [ $rc -ne 0 ]; then
    echo "[rsync.sh]remote version retrieval fail"
    return $rc
  fi
  diff -q $DST_VERSION_FILE $DST_REMOTE_VERSION_FILE 
  return $?
}

chk_inprogress() {
  if [ -f $INPROGRESS_FILE ]; then
    return 1;
  else
    return 0;
  fi
}

do_sync() {
  # remove old version info to make sure updated even if sizes is same when '-s' option
  rm -f "$DST_VERSION_FILE"

  # mark in progress
  touch $INPROGRESS_FILE

  #sync update dir first
  if [ ! -d $DST_DIR/device ]; then
    mkdir -p $DST_DIR/device
  fi

  RSYNC_PASSWORD=$OPT_PASSWORD \
  $RSYNC $RSYNC_OPTIONS \
  --delete-after \
  $STUNNEL_OPT \
  $SRC_URL/device/update $DST_DIR/device

  RSYNC_PASSWORD=$OPT_PASSWORD \
  $RSYNC $RSYNC_OPTIONS \
  --delete-after \
  --delete-excluded \
  "$FILTER_OPTION" "$FILTER_FILE_OPTION" \
  $STUNNEL_OPT \
  $SRC_URL $DST_DIR

  return $?
}

####show help ####
if [ $OPT_HELP -eq 1 ]; then
  show_help
  exit 1;
fi

if [ $OPT_SIZE_ONLY -eq 1  ]; then
  RSYNC_OPTIONS="-rlvz --size-only"
else
  RSYNC_OPTIONS="-avz"
fi

####get remote version ####
if [ $OPT_GET_VERSION -eq 1  ]; then
  rc=0
  get_version || rc=$?
  if [ $rc -ne 0 ]; then
    echo "[rsync.sh]remote version retrieval fail"
    exit 1;
  fi
  exit 0;
fi

#### proceed only if previous try failed
if [ $OPT_RECOVER -eq 1 ]; then
  rc=0
  chk_inprogress || rc=$?
  if [ $rc -eq 0 ]; then
#    echo "[rsync.sh]no need to recover, do not proceed"
    exit;
  fi
fi

#### proceed only if version mismatch
if [ $OPT_CHECK_VERSION -eq 1 ]; then
  rc=0
  chk_version || rc=$?
  if [ $rc -eq 0 ]; then
    echo "[rsync.sh]alreay up-to-date, do not proceed"
    exit;
  fi
fi

##### do sync #####
do_sync
