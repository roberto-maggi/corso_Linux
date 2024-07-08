#!/bin/sh

VIP=10.0.0.230
PROT=http
PORT=80

VARS="--silent --max-time 2 --insecure" 

errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl $VARS $PROT://localhost:$PORT/ -o /dev/null || errorExit "Error GET $PROT://localhost:$PORT/"
if ip addr | grep -q $VIP; then
  curl $VARS $PROT://$VIP:$PORT/ -o /dev/null || errorExit "Error GET $PROT://$VIP:$PORT/"
fi