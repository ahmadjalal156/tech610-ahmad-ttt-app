#!/bin/bash
## TESTED: 2026-08-28
## TESTED BY: Ahmad Jalal
## TESTED ON: AWS (Ubuntu 24.04 LTS, eu-west-1)
## AIM: Stage 3 app VM (user data only) - app on port 80 via nginx, in DB mode
## PURPOSE: App tier that self-provisions at first boot and serves on port 80

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Database connection string -> the stage 3 DB VM's private IP
export MONGODB_URI="mongodb://172.31.48.190:27017/tictactoe"

# --- STEP 1: Update and install base tools ---
echo ">>> Updating and installing curl, git..."
apt-get update -y
apt-get install -y curl git

# --- STEP 2: Install Node.js 20 ---
echo ">>> Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# --- STEP 3: Install pm2 globally ---
echo ">>> Installing pm2..."
npm install -g pm2

# --- STEP 4: Clone the app ---
echo ">>> Cloning the app..."
cd /home/ubuntu
git clone https://github.com/ahmadjalal156/tech610-ahmad-ttt-app.git app
cd app

# --- STEP 5: Install app dependencies ---
echo ">>> Installing app dependencies..."
npm install

# --- STEP 6: Start the app under pm2 (DB mode, port 3000) ---
echo ">>> Starting the app with pm2..."
MONGODB_URI="$MONGODB_URI" pm2 start index.js --name ttt-app
pm2 save

# --- STEP 7: Install and configure nginx as a reverse proxy (80 -> 3000) ---
echo ">>> Installing and configuring nginx..."
apt-get install -y nginx
tee /etc/nginx/sites-available/default > /dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# --- STEP 8: Test and restart nginx ---
echo ">>> Testing and restarting nginx..."
nginx -t
systemctl enable nginx
systemctl restart nginx

echo ">>> Done. App should be live on port 80 in database mode."
