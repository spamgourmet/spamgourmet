#!/bin/bash
#This script expects to be run from the spamgourmet-clone main directory
echo '========================= spamgourmet server installation start'
source sg-server-config.sh

cd $SCRIPT_BASE_DIR

function development_packages {
  echo '##########################################################################'
  echo '### install mandatory packages'
  echo '##########################################################################'
  apt-get update
  apt-get upgrade -y
  apt-get autoremove
  apt-get install -y shunit2
}

development_packages
