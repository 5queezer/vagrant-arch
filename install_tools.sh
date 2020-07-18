#!/bin/bash

echo -e "\n--- Installing tools ---\n"
pacman -Sq git composer npm yarn vim --noconfirm 2>&1 | tee -a /var/log/vm_build.log

