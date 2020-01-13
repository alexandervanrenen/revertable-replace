#!/bin/sh
# --------------------------------------------------------------------------------------
META_FILE=~/.rr/counter.dat
RR_DIR=~/.rr
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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

  SEARCH_PATTERN="$2"
  REPLACEMENT_WORD="$3"
  DIRECTORY="$4"


  if [ $# -lt 4 ]; then
      echo "Usage: rr replace <pattern> <replacement> <folder> [options]"
      exit -1
  fi

  if ! [[ -d $DIRECTORY ]]; then
      echo "Invalid directory: '$DIRECTORY'"
      exit -1
  fi

  getNextCounter
  COUNTER=$?

  FILES=`ag -l $SEARCH_PATTERN -- $DIRECTORY`
  for f in $FILES; do
    $DIR/patch_maker "$SEARCH_PATTERN" "$REPLACEMENT_WORD" $f | git diff --no-index $f - >> ~/.rr/rr_$COUNTER.patch
    $DIR/patch_maker "$SEARCH_PATTERN" "$REPLACEMENT_WORD" $f | git diff --no-index --color=always $f - >> ~/.rr/rr_color_$COUNTER.patch
  done
  touch ~/.rr/rr_$COUNTER.patch # Make sure file exists even if there is no diff

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
function undo() {
  if [ $# -gt 2 ]; then
    echo "Usage: rr undo [patch_id]"
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
function show() {
  if [ $# -gt 2 ]; then
    echo "Usage: rr show [patch_id]"
    echo "Use 'rr list' to figure out the patch_id"
    exit -1
  fi

  if [ $# -eq 1 ]; then
    getLastCounter
    PATCH_ID=$?
  else
    PATCH_ID=$2
  fi

  if [ -f "~/.rr/rr_color_${PATCH_ID}.patch" ]; then
    echo "Can not find patch file."
    exit -1
  fi

  cat ~/.rr/rr_color_${PATCH_ID}.patch
}
# --------------------------------------------------------------------------------------
function cludy() {
  DIRECTORY="$1"

  if [ $# -lt 1 ]; then
      echo "Usage: rr cludy <folder>"
      exit -1
  fi

  if ! [[ -d $DIRECTORY ]]; then
      echo "Invalid directory: '$DIRECTORY'"
      exit -1
  fi

  getNextCounter
  COUNTER=$?

  FILES=`find $DIRECTORY | grep "[ch]pp$"`
  for f in $FILES; do
    $DIR/cludy $f | git diff --no-index $f - >> ~/.rr/rr_$COUNTER.patch
    $DIR/cludy $f | git diff --no-index --color=always $f - >> ~/.rr/rr_color_$COUNTER.patch
  done
  touch ~/.rr/rr_$COUNTER.patch # Make sure file exists even if there is no diff

  printf "cludy in \"$DIRECTORY\"\n" >> $META_FILE
}
# --------------------------------------------------------------------------------------
function printHelpAndExit() {
  echo "Options are: list, replace, apply, undo, clean, show"
  echo "rr replace <pattern> <replacement> <folder> [options]"
  echo "rr show [patch_id]"
  echo "rr undo [patch_id]"
  echo "rr apply [patch_id]"
  exit -1
}
# --------------------------------------------------------------------------------------
# program entry -> main

mkdir -p ~/.rr

if [ $# -lt 1 ]; then
  echo "Need at least one argument."
  printHelpAndExit
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

if [ "$1" = "undo" ]; then
  undo $@
  exit 0
fi

if [ "$1" = "show" ]; then
  show $@
  exit 0
fi

if [ "$1" = "clean" ]; then
  echo "All caches cleaned."
  rm ~/.rr/*
  exit 0
fi

if [ "$1" = "cludy" ]; then
  cludy $2
  exit 0
fi

echo "Unkown command: $1"
printHelpAndExit
