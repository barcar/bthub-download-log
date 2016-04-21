#!/bin/bash

ROUTER_PASSWORD=$1
DOWNLOAD_SCRIPT=${BASH_SOURCE%/*}/download-log.sh
LOG_FILE=${BASH_SOURCE%/*}/bthub.log
TMP_FILE=/tmp/bthub_old.log
DIFF_FILE=${BASH_SOURCE%/*}/bthub_diff.log


trap cleanUp EXIT SIGINT SIGTERM

function cleanUp() {
  [ -f ${TMP_FILE} ] && rm -f ${TMP_FILE}
}

function diffLog() {

  # Move last downloaded log (if it exists) to temp location
  [ -f ${LOG_FILE} ] && mv ${LOG_FILE} ${TMP_FILE}

  # Do new log download using external script
  ${DOWNLOAD_SCRIPT} ${ROUTER_PASSWORD}

  if grep 'Admin login successful' ${LOG_FILE} > /dev/null
  then
    echo "Starting diff"
    # Output any new lines since last execution
    diff --new-file --old-line-format='' --new-line-format='%L' --unchanged-line-format='' ${TMP_FILE} ${LOG_FILE} > ${DIFF_FILE}
  else
    echo "Log not found"
    # Create an empty diff file if nothing downloaded
    :> ${DIFF_FILE}
    exit 1
  fi
}

diffLog
