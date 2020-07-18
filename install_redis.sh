#!/bin/bash

echo -e "\n--- Installing Redis ---\n"
pacman -Sq redis php-redis --noconfirm 2>&1 | tee -a /var/log/vm_build.log

FILE=/etc/httpd/conf/httpd.conf
if grep -q "^#.*modules/mod_socache_redis.so" $FILE; then
  sed -i 's/\(#\s*\)\(.*modules\/mod_socache_redis\.so.*\)/\2/' $FILE
fi

systemctl start redis.service
systemctl enable redis.service