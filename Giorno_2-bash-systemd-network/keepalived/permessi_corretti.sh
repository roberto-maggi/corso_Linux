#!/bin/bash

KEEPALIVED_DIR=/etc/keepalived
chmod 0500 $KEEPALIVED_DIR
chmod 0100 $KEEPALIVED_DIR/check_ha.sh
chmod 0400 $KEEPALIVED_DIR/keepalived.conf
chown -R root:root $KEEPALIVED_DIR