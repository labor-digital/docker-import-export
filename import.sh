#!/bin/bash
if [ -d "/var/www" ]
then
  echo "# Using this basedir: /var/www/"
  cd /var/www

  ls -l
else
  echo "ERROR: Directory /var/www does not exist"
  exit 1
fi