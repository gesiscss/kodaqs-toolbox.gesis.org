#!/bin/bash

cd ./demo || exit
find _site/ -type f -print0 | xargs -0 chmod 0644
find _site/ -type d -print0 | xargs -0 chmod 0755
sudo mkdir -p /var/www/test
sudo rm -rf /var/www/test/*
sudo cp -r _site/* /var/www/test/
sudo chown -R www-data:www-data /var/www/test/*
sudo systemctl restart nginx
