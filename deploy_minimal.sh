#!/bin/bash

cd ./minimal_example || exit
sudo mkdir -p /var/www/minimal
sudo rm -rf /var/www/minimal/*
sudo cp -r ./minimal_example/_site/* /var/www/minimal/
sudo chown -R www-data:www-data /var/www/minimal/*
sudo chmod -R 755 /var/www/minimal/*
sudo systemctl restart nginx
