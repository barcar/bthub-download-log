#!/bin/bash

ROUTER_PASSWORD=$1
ROUTER_IP=$(/sbin/ip route | awk '/default/ { print $3 }')
ROUTER_BASE_URL="http://${ROUTER_IP}"
COOKIE_JAR=/tmp/cookies.txt
OUTPUT_FILE=/tmp/output.html
LOG_FILE=${BASH_SOURCE%/*}/bthub.log

trap cleanUp EXIT SIGINT SIGTERM

function cleanUp() {
  [ -f ${COOKIE_JAR} ] && rm -f ${COOKIE_JAR}
  [ -f ${OUTPUT_FILE} ] && rm -f ${OUTPUT_FILE}
}

function setup() {
  local LOGIN_HTML=$(curl -s -L --cookie-jar ${COOKIE_JAR} "${ROUTER_BASE_URL}/index.cgi?active_page=9099")

  REQUEST_ID=$(echo ${LOGIN_HTML} | grep -o 'request_id=[0-9][^&]*' | head -n1)
  AUTH_KEY=$(echo ${LOGIN_HTML} | sed -n '/auth_key/s/.*name="auth_key"\s\+value="\([^"]\+\).*/\1/p')
  PASSWORD_FIELD_NAME=$(echo ${LOGIN_HTML} | grep -o "password_[0-9][^']*" | head -n1)  
  PASSWORD_MD5=$(echo -n "${ROUTER_PASSWORD}${AUTH_KEY}" | echo $(openssl md5 | cut -f2 -d=))
}

function setPostId() {
  local LOG_HTML=$(curl -s -L --cookie ${COOKIE_JAR} "${ROUTER_BASE_URL}/index.cgi?${REQUEST_ID}&active_page=9122")
  POST_ID=$(echo ${LOG_HTML} | sed -n '/post_id/s/.*name="post_id"\s\+value="\([^"]\+\).*/\1/p')
}

function downloadLog() {
  #Setup prerequisites
  setup

  #Do login
  postDataToRouter "${REQUEST_ID}&${PASSWORD_FIELD_NAME}=&md5_pass=${PASSWORD_MD5}&auth_key=${AUTH_KEY}&active_page=9142&active_page_str=bt_login&mimic_button_field=submit_button_login_submit%3A+..&button_value=&post_id=0" 

  #Grab the post_id hidden variable for the reboot post request
  setPostId

  #Do download
  postDataToRouter "${REQUEST_ID}&active_page=9152&active_page_str=page_event&mimic_button_field=submit_button_bt_save%3A+..&button_value=&post_id=${POST_ID}" 

if grep 'Admin login successful' ${OUTPUT_FILE} > /dev/null
  then
    echo "Log downloaded successfully"
    # move temp file to final location and reverse order (oldest at top)
    tac ${OUTPUT_FILE} > ${LOG_FILE}
  else
    echo "Log download failed"
    exit 1
  fi
}

function postDataToRouter() {
  local POST_DATA=$1

  curl "${ROUTER_BASE_URL}/index.cgi" -H 'Accept-Encoding: gzip,deflate,sdch' \
                                      -H 'Accept-Language: en-GB,en-US;q=0.8,en;q=0.6' \
                                      -H 'User-Agent: cURL' \
                                      -H 'Content-Type: application/x-www-form-urlencoded' \
                                      -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
                                      -H 'Cache-Control: max-age=0' \
                                      -H 'Connection: keep-alive' \
                                      -o ${OUTPUT_FILE} \
                                      --data "${POST_DATA}" \
                                      --compressed \
                                      --cookie ${COOKIE_JAR} \
                                      --cookie-jar ${COOKIE_JAR} \
                                      -L > /dev/null 2>&1
}

downloadLog
