#!/bin/bash
# Install Nginx
sudo apt update
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
sudo ufw allow 'Nginx Full'
sudo ufw reload