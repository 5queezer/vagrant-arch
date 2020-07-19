#!/bin/bash
# First Parameter: user
# Second Parameter: password (optional)
# run as root
#
PASS=$2
[ -z $2 ] && PASS=`openssl rand -base64 14`

mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE $1;
CREATE USER '$1'@'localhost' IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON $1.* TO '$1'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT \
&& echo "MySQL user created."
&& echo "Username:   $1"
&& [ -z $2 ] && echo "Password:   $PASS"
|| echo "Error" > /dev/stderr
