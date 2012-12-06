#!/bin/sh

FINS_HOME=/srv/delta-home/monotype/webapps/Keyboard
export FINS_HOME
while /bin/true ; 
do
  $FINS_HOME/bin/start.sh -p8080
  sleep 10
done;
