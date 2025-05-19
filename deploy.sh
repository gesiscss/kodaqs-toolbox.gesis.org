#!/bin/bash

cd ./demo || exit
sudo rm -rf /var/www/html/*
sudo cp -r _site/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/*
sudo chmod -R 755 /var/www/html/*
sudo systemctl restart nginx
