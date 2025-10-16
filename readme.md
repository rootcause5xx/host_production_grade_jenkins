# 🚀 Jenkins Production Setup on AWS EC2 with HTTPS & Nginx Reverse Proxy

## 📖 Overview
This project demonstrates how to deploy a **production-grade Jenkins** setup on an **AWS EC2** instance behind **Nginx reverse proxy** with **Let's Encrypt SSL** and **custom domain integration using Route 53**.

It is designed to be **secure, reliable, and accessible via HTTPS**.


> Note: Jenkins can be hosted in several ways depending on your infrastructure and scalability needs:
> Note: Here in our case we put jenkins in the public subnet but the best practice is to keep in private subnet of internal traffic only and expose it others by using Load Balancer or nginx using reverse proxy so the nginx is only exposed jenkins stays private but to save cost for my personal use we kept it on the public subnet.
> - **EC2 Instance:** Deploy Jenkins on a virtual server for full control over OS and configuration.
> - **ECS / Fargate:** Containerize Jenkins and run it on AWS ECS or Fargate for easier scaling and management.
> - **Serverless Pipelines:** Use AWS services like Lambda, CodeBuild, and CodePipeline to run Jenkins tasks without managing servers.
> - **On-Premise Servers:** Traditional hosting within your own data center for full control and compliance.
> - **Docker on Any Cloud Provider:** Run Jenkins inside a Docker container on any cloud VM or cluster for portability and consistency.
>
> In this project, we are using a **simple EC2 instance (t2.medium)** to demonstrate a production-ready Jenkins setup.

---

## 🧩 Architecture Diagram
![Architecture Diagram](docs/architecture-diagram.png)

**Traffic Flow:**
```

User → (HTTPS) → Nginx Reverse Proxy → Jenkins (8080)
↑
Let’s Encrypt SSL

````

---

## ⚙️ Tech Stack
- **AWS EC2 (Ubuntu 22.04)**
- **Jenkins**
- **Nginx (Reverse Proxy)**
- **Let's Encrypt (Certbot)**
- **AWS Route 53 (DNS Management)**
- **Elastic IP**

---

## 🪜 Implementation Steps

### Step 1: Launch EC2 Instance
1. Launch an **Ubuntu EC2 instance** (Ubuntu 22.04 recommended).
2. Assign an **Elastic IP (EIP)** so the public IP remains static.
3. Configure **Security Groups** to allow inbound traffic:
   - **Port 22** – SSH
   - **Port 80** – HTTP
   - **Port 443** – HTTPS

---

### Step 2: Install Jenkins
```bash
# Update packages
sudo apt update

# Install Java (required for Jenkins)
sudo apt install openjdk-17-jdk -y

# Add Jenkins repository key and source
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Enable and start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins
````

* Jenkins runs on **port 8080** by default.
* Verify:

```bash
sudo systemctl status jenkins
```

---

### Step 3: Install & Configure Nginx (Reverse Proxy)

```bash
# Install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

* Create a site-specific Nginx config: `/etc/nginx/sites-available/jenkins.conf`

Example `jenkins.conf`:

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/jenkins.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

✅ Jenkins is now accessible via **HTTP** on your domain (before HTTPS setup).

---

### Step 4: Route 53 Domain Setup

We use **AWS Route 53** to point our custom domain to the Jenkins EC2 instance.

1. **Allocate an Elastic IP (EIP)** and associate it with the Jenkins EC2 instance.

2. **Create a Hosted Zone** in Route 53 for your domain (e.g., `example.com`).

3. **Create an A Record** pointing `jenkins.example.com` to the Elastic IP:

   * Type: **A – IPv4 address**
   * Value: **Elastic IP of EC2**
   * Routing Policy: **Simple**
   * TTL: default (300s)

4. **Verify DNS Resolution**

```bash
ping jenkins.example.com
```

The command should return your Elastic IP.

> ⚠️ Note: If your domain is registered outside AWS, update its Name Servers (NS records) to match Route 53.

---

### Step 5: Enable HTTPS using Let’s Encrypt & Certbot

We secure the domain using **Let’s Encrypt SSL** with **Certbot**.

```bash
# Install Certbot with Nginx plugin
sudo apt install certbot python3-certbot-nginx -y

# Generate SSL certificate for your domain
sudo certbot --nginx -d jenkins.example.com

# Test auto-renewal (optional)
sudo certbot renew --dry-run
```

**What happens automatically:**

* Adds a **HTTPS server block** in `jenkins.conf`
* Redirects all HTTP traffic → HTTPS
* Configures SSL certificates at:

```
/etc/letsencrypt/live/jenkins.example.com/fullchain.pem
/etc/letsencrypt/live/jenkins.example.com/privkey.pem
```

Example `jenkins.conf` after HTTPS setup:

```nginx
server {
    listen 80;
    server_name jenkins.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name jenkins.example.com;

    ssl_certificate /etc/letsencrypt/live/jenkins.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/jenkins.example.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

✅ Jenkins is now accessible via **HTTPS**: `https://jenkins.example.com`

---

### Step 6: Verification

* Open browser: `https://jenkins.example.com`
* You should see Jenkins dashboard with a **green lock (SSL active)**
* Test auto-renewal to ensure certificates renew automatically.

---

## 📸 Screenshots

| Description       | Image                                         |
| ----------------- | --------------------------------------------- |
| Route 53 A Record | ![Route53](screenshots/route53-record.png)    |
| Certbot Success   | ![Certbot](screenshots/certbot-success.png)   |
| HTTPS Nginx       | ![HTTPS](screenshots/nginx-https.png)         |
| Jenkins Dashboard | ![Jenkins](screenshots/jenkins-dashboard.png) |

---

## 🧠 Key Learnings

* How to **secure Jenkins behind Nginx**
* How **Let’s Encrypt SSL certificates** work
* Configuring **Route 53 for domain resolution**
* Setting up **HTTP → HTTPS redirection**
* Using **Elastic IP** to maintain a static public IP

---

## 📝 References / Resources

* [Jenkins Official Docs](https://www.jenkins.io/doc/)
* [Nginx Reverse Proxy Docs](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
* [Let’s Encrypt / Certbot Docs](https://certbot.eff.org/)
* [AWS Route 53 Documentation](https://docs.aws.amazon.com/route53/)

---

## 📜 Author

**Aman Patel**
DevOps Engineer | Cloud | AWS | CI/CD
[LinkedIn](#) • [GitHub](#)

```

---

This **full README.md** includes:

- All steps: EC2 → Jenkins → Nginx → Certbot → Route 53
- Correct `jenkins.conf` references
- Commands, code blocks, and explanations
- Screenshots placeholders
- Key learnings section for portfolio impact

---
