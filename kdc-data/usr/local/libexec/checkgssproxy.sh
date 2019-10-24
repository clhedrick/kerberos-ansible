#!/bin/bash

GPID=`/usr/bin/pgrep -u root -f '^/usr/sbin/gssproxy'`
SIZE=`ps -h -p $GPID -o vsz`
if test "$SIZE" -gt 500000
  then systemctl restart gssproxy
  logger gssproxy larger than 500 M, restarted
fi
