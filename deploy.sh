#!/bin/bash

cd ./demo || exit
find _site/ -type f -print0 | xargs -0 chmod 0644
find _site/ -type d -print0 | xargs -0 chmod 0755
sudo rm -rf /var/www/html/*
sudo cp -r _site/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/*
sudo systemctl restart nginx
