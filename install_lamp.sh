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
function embedded_phpinfo()
{
    ob_start();
    phpinfo();
    \$phpinfo = ob_get_contents();
    ob_end_clean();
    \$phpinfo = preg_replace('%^.*<body>(.*)</body>.*$%ms', '$1', \$phpinfo);
    return \$phpinfo;
}
?>

<!doctype html>
<html>
<head>
<title>PHP Test Page</title>
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css" integrity="sha384-9aIt2nRpC12Uk9gS9baDl411NQApFmC26EwAOH8WgZl5MYYxFfc+NcPb1dKGj7Sk" crossorigin="anonymous">

<style type='text/css'>
  #phpinfo {}
  #phpinfo pre {margin: 0; font-family: monospace;}
  #phpinfo a:link {color: #009; text-decoration: none; background-color: #fff;}
  #phpinfo a:hover {text-decoration: underline;}
  #phpinfo table {border-collapse: collapse; border: 0; width: 934px; box-shadow: 1px 2px 3px #ccc;}
  #phpinfo .center {text-align: center;}
  #phpinfo .center table {margin: 1em auto; text-align: left;}
  #phpinfo .center th {text-align: center !important;}
  #phpinfo td, th {border: 1px solid #666; font-size: 75%; vertical-align: baseline; padding: 4px 5px;}
  #phpinfo h1 {font-size: 150%;}
  #phpinfo h2 {font-size: 125%;}
  #phpinfo .p {text-align: left;}
  #phpinfo .e {background-color: #ccf; width: 300px; font-weight: bold;}
  #phpinfo .h {background-color: #99c; font-weight: bold;}
  #phpinfo .v {background-color: #ddd; max-width: 300px; overflow-x: auto; word-wrap: break-word;}
  #phpinfo .v i {color: #999;}
  #phpinfo img {float: right; border: 0;}
  #phpinfo hr {width: 934px; background-color: #ccc; border: 0; height: 1px;}
</style>

</head>
<body>
<div id="phpinfo">
<?php echo embedded_phpinfo(); ?>
</div>
</html>
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
