#!/bin/bash -e
sleep 120
systemctl restart ssh
rm -f $0