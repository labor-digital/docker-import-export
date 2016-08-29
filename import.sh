#!/bin/bash

echo ">> Waiting for mysql to start"
while ! nc -z $APP_MYSQL_HOST $MYSQL_PORT; do
  sleep 3
done


if [ -f "/var/www/html_import/do_import" ]
then
	echo "Import started."
	rm -R -f /var/www/html_data/*
	cp -R /var/www/html_import/data/* /var/www/html_data
	
	sqlinitstr="DROP USER IF EXISTS ${APP_MYSQL_USER}@'%';
CREATE USER ${APP_MYSQL_USER}@'%' IDENTIFIED BY '${APP_MYSQL_PASS}';
DROP DATABASE IF EXISTS ${APP_MYSQL_DATABASE};
CREATE DATABASE ${APP_MYSQL_DATABASE};
GRANT SELECT,INSERT,UPDATE  ON ${APP_MYSQL_DATABASE}.* TO ${APP_MYSQL_USER}@'%';
FLUSH PRIVILEGES;
"
	mysql --host="${APP_MYSQL_HOST}" --user='root' --password="${MYSQL_ROOT_PASSWORD}" -f <<< $sqlinitstr
	mysql --host="${APP_MYSQL_HOST}" --user='root' --password="${MYSQL_ROOT_PASSWORD}" -f "${APP_MYSQL_DATABASE}" < /var/www/html_import/dump.sql
	
	rm -f /var/www/html_import/do_import
	echo "Import ready."
else
	echo "No Import."
fi