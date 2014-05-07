#!/bin/sh
PATH=/usr/local/pike/7.9.5/bin:$PATH
export PATH
FINS_HOME=/srv/delta-home/keyboard-deploy/Keyboard
export FINS_HOME
while /bin/true ; 
do
  $FINS_HOME/bin/start.sh -p8080 --no-virtual
  sleep 10
done;
