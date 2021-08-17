#!/bin/bash

echo ">> Waiting for mysql to start"
while ! nc -z $APP_MYSQL_HOST 3306; do
  sleep 3
done


if [ -f "/var/www/html_import/do_export" ]
then
	echo "Export started."
	mkdir /var/www/html_import/data
	rm -R -f /var/www/html_import/data/*
	cp -R /var/www/html_data/* /var/www/html_import/data
	
	mysqldump  \
		--host="${APP_MYSQL_HOST}" \
		--user='root' \
		--password="${MYSQL_ROOT_PASSWORD}" \
		--column-statistics=0 \
		"${APP_MYSQL_DATABASE}" > /var/www/html_import/dump.sql
	
	if [ -z ${APP_MYSQL_DATABASE_COUNT+x} ]
	then
		APP_MYSQL_DATABASE_COUNT=1
	fi
	
	if [ $APP_MYSQL_DATABASE_COUNT -gt 1 ]
	then
		for idx in $(seq 1 `expr $APP_MYSQL_DATABASE_COUNT - 1`)
		do
			mysqldump  \
			--host="${APP_MYSQL_HOST}" \
			--user='root' \
			--password="${MYSQL_ROOT_PASSWORD}" \
			--column-statistics=0 \
			"${!APP_MYSQL_DATABASE_IDX_NAME}" > /var/www/html_import/dump_${idx}.sql
		done
	fi
	
	rm -f /var/www/html_import/do_export
	echo "Export ready."
else
	echo "No Export."
fi


if [ -f "/var/www/html_import/do_import" ]
then
	echo "Import started."
	if [ "$(ls -A /var/www/html_import/data)" ]
	then
	  rm -R -f /var/www/html_data/*
	  cp -R /var/www/html_import/data/* /var/www/html_data
	fi

	sqlinitstr="DROP USER ${APP_MYSQL_USER}@'%';
CREATE USER ${APP_MYSQL_USER}@'%' IDENTIFIED BY '${APP_MYSQL_PASS}';
DROP DATABASE IF EXISTS ${APP_MYSQL_DATABASE};
CREATE DATABASE ${APP_MYSQL_DATABASE} CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT SELECT, INSERT, UPDATE, EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, REFERENCES, TRIGGER, LOCK TABLES ON ${APP_MYSQL_DATABASE}.* TO ${APP_MYSQL_USER}@'%';
FLUSH PRIVILEGES;
"
	mysql --host="${APP_MYSQL_HOST}" --user='root' --password="${MYSQL_ROOT_PASSWORD}" -f <<< $sqlinitstr
	mysql --host="${APP_MYSQL_HOST}" --user='root' --password="${MYSQL_ROOT_PASSWORD}" -f "${APP_MYSQL_DATABASE}" < /var/www/html_import/dump.sql
	
	if [ -z ${APP_MYSQL_DATABASE_COUNT+x} ]
	then
		APP_MYSQL_DATABASE_COUNT=1
	fi
	
	if [ $APP_MYSQL_DATABASE_COUNT -gt 1 ]
	then
		for idx in $(seq 1 `expr $APP_MYSQL_DATABASE_COUNT - 1`)
		do
			APP_MYSQL_DATABASE_IDX_NAME="APP_MYSQL_DATABASE_$idx"
			sqlinitstr="DROP DATABASE IF EXISTS ${!APP_MYSQL_DATABASE_IDX_NAME};
CREATE DATABASE ${!APP_MYSQL_DATABASE_IDX_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT SELECT, INSERT, UPDATE, EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, REFERENCES, TRIGGER, LOCK TABLES ON ${!APP_MYSQL_DATABASE_IDX_NAME}.* TO ${APP_MYSQL_USER}@'%';
FLUSH PRIVILEGES;
"
			mysql --host="${APP_MYSQL_HOST}" --user='root' --password="${MYSQL_ROOT_PASSWORD}" -f <<< $sqlinitstr
			mysql --host="${APP_MYSQL_HOST}" --user='root' --password="${MYSQL_ROOT_PASSWORD}" -f "${!APP_MYSQL_DATABASE_IDX_NAME}" < /var/www/html_import/dump_${idx}.sql
		done
	fi
	
	rm -f /var/www/html_import/do_import
	echo "Import ready."
else
	echo "No Import."
fi
