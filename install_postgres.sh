#!/bin/bash

echo -e "\n--- Installing Postgres ---\n"
pacman -Sq postgresql php-pgsql --noconfirm 2>&1 | tee -a /var/log/vm_build.log

if [ ! -d /var/lib/postgres/data ]; then
  mkdir -p /var/lib/postgres
  chown postgres:postgres /var/lib/postgres
  su -c "initdb -D /var/lib/postgres/data" - postgres
fi

systemctl enable postgresql.service
systemctl restart postgresql.service
