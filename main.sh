#!/bin/sh
# --------------------------------------------------------------------------------------
META_FILE=~/.rr/counter.dat
RR_DIR=~/.rr
# --------------------------------------------------------------------------------------
function getLastCounter() {
  if [ ! -f "$META_FILE" ]; then
    value=0
  else
    value=`tail -n1 $META_FILE | cut -d ':' -f1`
  fi
  return $value
}
# --------------------------------------------------------------------------------------
function getNextCounter() {
  getLastCounter
  value=`expr ${?} + 1`
  printf "${value}: " >> $META_FILE
  return $value
}
# --------------------------------------------------------------------------------------
function replace() {
  getNextCounter
  COUNTER=$?

  if [ $# -lt 4 ]; then
      echo "Usage: rr replace <pattern> <replacement> <folder> [options]"
      exit -1
  fi

  SEARCH_PATTERN=$2
  REPLACEMENT_WORD=$3
  DIRECTORY=$4

  if ! [[ -d $DIRECTORY ]]; then
      echo "Invalid directory: '$DIRECTORY'"
      exit -1
  fi

  FILES=`find $DIRECTORY | grep "[ch]pp"`
  for f in $FILES; do
    ./a.out $SEARCH_PATTERN $REPLACEMENT_WORD $f | git diff --no-index $f - > ~/.rr/rr_$COUNTER.patch
  done

  printf "\"$SEARCH_PATTERN\" -> \"$REPLACEMENT_WORD\" in \"$DIRECTORY\"\n" >> $META_FILE
}
# --------------------------------------------------------------------------------------
function list() {
  if [[ -f $META_FILE ]]; then
      tail -n10 $META_FILE
  fi
}
# --------------------------------------------------------------------------------------
function apply() {
  if [ $# -gt 2 ]; then
    echo "Usage: rr apply [patch_id]"
    echo "Use 'rr list' to figure out the patch_id"
    exit -1
  fi

  if [ $# -eq 1 ]; then
    getLastCounter
    PATCH_ID=$?
  else
    PATCH_ID=$2
  fi

  if [ -f "~/.rr/rr_${PATCH_ID}.patch" ]; then
    echo "Can not find patch file."
    exit -1
  fi

  patch -p1 < ~/.rr/rr_${PATCH_ID}.patch
  echo "Applied patch: "`head -${PATCH_ID} $META_FILE | tail -1`
}
# --------------------------------------------------------------------------------------
function revert() {
  if [ $# -gt 2 ]; then
    echo "Usage: rr revert [patch_id]"
    echo "Use 'rr list' to figure out the patch_id"
    exit -1
  fi

  if [ $# -eq 1 ]; then
    getLastCounter
    PATCH_ID=$?
  else
    PATCH_ID=$2
  fi

  if [ -f "~/.rr/rr_${PATCH_ID}.patch" ]; then
    echo "Can not find patch file."
    exit -1
  fi

  patch -p1 -R < ~/.rr/rr_${PATCH_ID}.patch
  echo "Reverted patch: "`head -${PATCH_ID} $META_FILE | tail -1`
}
# --------------------------------------------------------------------------------------
# program entry -> main

mkdir -p ~/.rr

if [ $# -lt 1 ]; then
  echo "Need at least one argument."
  echo "Options are: list, replace, apply, revert, clean"
  exit -1
fi

if [ "$1" = "replace" ]; then
  replace $@
  exit 0
fi

if [ "$1" = "list" ]; then
  list $@
  exit 0
fi

if [ "$1" = "apply" ]; then
  apply $@
  exit 0
fi

if [ "$1" = "revert" ]; then
  revert $@
  exit 0
fi

if [ "$1" = "clean" ]; then
  echo "All caches cleaned."
  rm ~/.rr/*
  exit 0
fi

echo "Unkown command: $1"
echo "Options are: list, replace, apply, revert, clean"
exit -1
