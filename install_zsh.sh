#!/bin/bash

echo -e "\n--- Installing zsh ---\n"
pacman -Sq zsh grml-zsh-config --noconfirm 2>&1 | tee -a /var/log/vm_build.log
ZSH_BIN=$(whereis zsh | cut -f 2 -d' ')

for user in root vagrant; do
  chsh -s $ZSH_BIN $user
  su -c "touch ~/.zshrc" - $user
done
