#!/bin/bash

cd ./demo || exit
sudo rm -rf /var/www/html/*
sudo cp -r _site/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/*
sudo find /var/www/html/ -type f -print0 | xargs -0 chmod 0644
sudo find /var/www/html/ -type d -print0 | xargs -0 chmod 0755
sudo systemctl restart nginx
