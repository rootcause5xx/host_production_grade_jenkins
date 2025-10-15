#!/bin/bash
#Create a reverse proxy config:
sudo bash -c 'cat > /etc/nginx/sites-available/jenkins <<EOF
server {
    server_name jenkins.appleslabs.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/jenkins.appleslabs.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/jenkins.appleslabs.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
server {
    if ($host = jenkins.appleslabs.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name jenkins.appleslabs.com;
    return 404; # managed by Certbot


}

server {
    listen 443 ssl;
    server_name 15.206.48.192;

    ssl_certificate /etc/letsencrypt/live/jenkins.appleslabs.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/jenkins.appleslabs.com/privkey.pem;

    return 301 https://jenkins.appleslabs.com$request_uri;
}
EOF'

# Enable the new configuration and disable the default
sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl reload nginx
sudo systemctl restart nginx
sudo systemctl status nginx

# Note: SSL certificates should be obtained using Certbot separately.
# Note: Replace jenkins.appleslabs.com with your actual domain name.

echo "Nginx installation and configuration completed."


# steps to install the cetrbot and generate ssl certificate

# Step 1: Install Certbot and Nginx plugin
sudo apt install certbot python3-certbot-nginx -y

# Step 2: Generate SSL certificate for your domain
sudo certbot --nginx -d yourdomain.com

# Step 3: Test automatic renewal
sudo certbot renew --dry-run

# Step 4: Verify Nginx configuration and restart Nginx
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl restart nginx
sudo systemctl status nginx
# Note: Replace yourdomain.com with your actual domain name.
# Note: Ensure that your domain's DNS records point to your server's IP address before running Certbot.

# Step 5: Check the installed certificates and its paths
sudo certbot certificates

# attach certificate path to nginx config file
# The SSL configuration is already included in the Nginx config above.
# Make sure to replace "jenkins.appleslabs.com" with your actual domain name in the Nginx configuration.
# Restart Nginx to apply changes.

