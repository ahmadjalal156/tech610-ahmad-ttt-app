#!/bin/bash
## TESTED: 2026-08-25
## TESTED BY: Ahmad Jalal
## TESTED ON: AWS (Ubuntu 24.04 LTS, eu-west-1)
## AIM: Provision a MongoDB 7.0 VM that survives imaging (kernel pinned to 6.8)
## PURPOSE: Database tier for the Tic Tac Toe app

# Run apt without interactive prompts (Ubuntu 24.04 needrestart etc.)
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# --------------------------------------------
# STEP 1: Update the package list
# --------------------------------------------
echo "Updating the sources list..."
sudo apt update -y
echo "Done!"

# --------------------------------------------
# STEP 2: Pin the kernel BEFORE upgrading
#   apt upgrade would otherwise install a newer AWS kernel that
#   MongoDB refuses to start on. Holding the kernel meta-packages
#   keeps this box (and any image made from it) on the 6.8 GA kernel.
# --------------------------------------------
echo "Holding the kernel packages..."
sudo apt-mark hold linux-image-aws linux-headers-aws linux-aws
echo "Done!"

# --------------------------------------------
# STEP 3: Upgrade everything else
# --------------------------------------------
echo "Upgrading remaining packages..."
sudo apt upgrade -y
echo "Done!"

# --------------------------------------------
# STEP 4: Add the MongoDB 7.0 GPG key
# --------------------------------------------
echo "Installing the MongoDB GPG key..."
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "Done!"

# --------------------------------------------
# STEP 5: Add the MongoDB 7.0 repo
#   Note: uses the jammy (22.04) path. There is no noble (24.04)
#   7.0 repo, so the noble path 404s.
# --------------------------------------------
echo "Adding the MongoDB repo..."
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
echo "Done!"

# --------------------------------------------
# STEP 6: Install MongoDB
# --------------------------------------------
echo "Installing MongoDB..."
sudo apt update -y
sudo apt install -y mongodb-org
echo "Done!"

# --------------------------------------------
# STEP 7: Allow remote connections
#   Change bindIp from 127.0.0.1 to 0.0.0.0 so the app VM can connect.
# --------------------------------------------
echo "Opening MongoDB to the network..."
sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
echo "Done!"

# --------------------------------------------
# STEP 8: Start and enable MongoDB
# --------------------------------------------
echo "Starting and enabling MongoDB..."
sudo systemctl start mongod
sudo systemctl enable mongod
echo "Done!"

echo "Provisioning complete. MongoDB should be active on port 27017."
