#!/bin/sh

VIP=10.0.0.230
PORT=80
errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl --silent --max-time 2 --insecure https://localhost:$PORT/ -o /dev/null || errorExit "Error GET https://localhost:$PORT/"
if ip addr | grep -q $VIP; then
  curl --silent --max-time 2 --insecure https://$VIP:$PORT/ -o /dev/null || errorExit "Error GET https://$VIP:$PORT/"
fi