#!/bin/sh

FINS_HOME=$HOME/monotype-hg/webapps/Keyboard
export FINS_HOME
while /bin/true ; 
do
  $FINS_HOME/bin/start.sh -p8083
  sleep 10
done;
