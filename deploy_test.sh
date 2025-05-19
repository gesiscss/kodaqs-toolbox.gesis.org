#!/bin/bash

cd ./demo || exit
sudo mkdir -p /var/www/test
sudo rm -rf /var/www/test/*
sudo cp -r _site/* /var/www/test/
sudo chown -R www-data:www-data /var/www/test/*
sudo chmod -R 755 /var/www/test/*
sudo systemctl restart nginx
