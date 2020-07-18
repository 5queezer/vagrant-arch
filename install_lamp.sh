#!/bin/bash

echo -e "\n--- Installing LAMP ---\n"
pacman -Sq apache php php-apache mysql --noconfirm 2>&1 | tee -a /var/log/vm_build.log

FILE=/etc/hosts
if ! grep -q "localhost.localdomain" $FILE; then 
  echo "127.0.0.1  localhost.localdomain   localhost" >> $FILE
fi

FILE=/etc/httpd/conf/httpd.conf
if ! grep -q "modules/libphp7.so" $FILE; then
  # Make apache config changes for php
  # 
  sed -i '/unique_id_module/s/^/#/' $FILE # comment
  sed -i '/mpm_event_module/s/^/#/' $FILE
  sed -i 's/\(#\s*\)\(.*mpm_prefork_module.*\)/\2/' $FILE #uncomment
  sed -i '/^.*mpm_prefork_module.*/a LoadModule php7_module modules/libphp7.so\nAddHandler php7-script .php' $FILE

  echo -e "\n# Load PHP Module 7" >> $FILE
  echo -e "<IfModule php7_module>" >> $FILE
  echo -e "\tInclude conf/extra/php7_module.conf" >> $FILE
  echo -e "</IfModule>" >> $FILE
fi

# Write an default httpd-vhosts.conf file for /srv/http
grep -q "dummy-host.example.com" /etc/httpd/conf/extra/httpd-vhosts.conf \
&& cat << EOS > /etc/httpd/conf/extra/httpd-vhosts.conf 
# Virtual Hosts
#
# Required modules: mod_log_config

# If you want to maintain multiple domains/hostnames on your
# machine you can setup VirtualHost containers for them. Most configurations
# use only name-based virtual hosts so the server doesn't need to worry about
# IP addresses. This is indicated by the asterisks in the directives below.
#
# Please see the documentation at 
# <URL:http://httpd.apache.org/docs/2.4/vhosts/>
# for further details before you try to setup virtual hosts.
#
# You may use the command line option '-S' to verify your virtual host
# configuration.

#
# VirtualHost example:
# Almost any Apache directive may go into a VirtualHost container.
# The first VirtualHost section is used for all requests that do not
# match a ServerName or ServerAlias in any <VirtualHost> block.
#
<VirtualHost *:80>
    ServerAdmin mail@example.com
    DocumentRoot "/srv/http/default"
    ServerName default.vagrant
    ServerAlias www.default.vagrant
    ErrorLog "/var/log/httpd/default-error_log"
    CustomLog "/var/log/httpd/default-access_log" common
</VirtualHost>
EOS

# Uncomment httpd-vhosts.conf line
sed -i 's/\(#\)\(.*httpd-vhosts.conf\)/\2/' $FILE

[ ! -d /srv/http/default ] && mkdir -p /srv/http/default && chown http:http /srv/http/default
[ ! -f /srv/http/default/index.php ] && cat << EOS > /srv/http/default/index.php
<?php
phpinfo();
EOS


httpd -t  2>&1 | tee -a /var/log/vm_build.log
systemctl enable httpd.service
systemctl restart httpd.service

# echo -e "\n--- Installing Apache tools ---\n"
# pacman -Sq base-devel --noconfirm 2>&1 | tee -a /var/log/vm_build.log
# PATH=$PWD
# cd /tmp
# sudo -u vagrant curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/a2enmod-git.tar.gz
# sudo -u vagrant tar -xvzf a2enmod-git.tar.gz
# cd a2enmod-git
# sudo -u vagrant makepkg -s
# pacman -U *.zst --noconfirm
# cd $PATH
