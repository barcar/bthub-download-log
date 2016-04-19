BT Hub Download Log Script
==========================

Download the event log from a BT Business Hub 5 using the command line instead of using the nasty looking web interface. Useful for sending to a central log server. Can be configured as a cron job.

## Tested on
* Debian Jessie
* BT Business Hub 5

## Dependencies
* cURL

## How it works
cURL is used to spoof the HTTP POST requests that would usually be made from the Home Hub web UI. A series of requests are made to the router in order to login and download the log file.

## Usage
To download the log file from your BT Business Hub simply execute the download-log.sh script passing in your admin password. For example:

```bash
./download-log.sh abc123
```
