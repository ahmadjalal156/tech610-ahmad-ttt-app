#!/bin/bash
## TESTED: 2026-08-25
## TESTED BY: Ahmad Jalal
## TESTED ON: AWS (Ubuntu 24.04 LTS, eu-west-1)
## AIM: Provision a MongoDB 8.2.5 VM that survives imaging (kernel pinned to 6.8)
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
#   MongoDB 8.2.5 refuses to start on. Holding the kernel meta-packages
#   keeps this box (and any image made from it) on the 6.8 GA kernel,
#   which is what lets us meet the 8.2.5 requirement.
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
# STEP 4: Add the MongoDB 8.0 GPG key
# --------------------------------------------
echo "Installing the MongoDB GPG key..."
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "Done!"

# --------------------------------------------
# STEP 5: Add the MongoDB repos
#   8.0 and 8.2 lines are added so the pinned 8.2.5 packages resolve.
# --------------------------------------------
echo "Adding the MongoDB repos..."
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.2.list
echo "Done!"

# --------------------------------------------
# STEP 6: Install MongoDB (version pinned to 8.2.5)
# --------------------------------------------
echo "Installing MongoDB 8.2.5..."
sudo apt update -y
sudo apt-get install -y \
   mongodb-org=8.2.5 \
   mongodb-org-database=8.2.5 \
   mongodb-org-server=8.2.5 \
   mongodb-mongosh \
   mongodb-org-mongos=8.2.5 \
   mongodb-org-tools=8.2.5 \
   mongodb-org-database-tools-extra=8.2.5
echo "Done!"

# --------------------------------------------
# STEP 7: Allow remote connections
#   Replace the whole bindIp line rather than a bare 127.0.0.1, so no
#   other 127.0.0.1 in the file can be changed by accident.
# --------------------------------------------
echo "Opening MongoDB to the network..."
sudo sed -i 's/^  bindIp: 127.0.0.1/  bindIp: 0.0.0.0/' /etc/mongod.conf
echo "Done!"

# --------------------------------------------
# STEP 8: Start and enable MongoDB
#   start  = picks up the new bindIp setting
#   enable = starts MongoDB automatically when the VM reboots
# --------------------------------------------
echo "Starting and enabling MongoDB..."
sudo systemctl start mongod
sudo systemctl enable mongod
echo "Done!"

echo "Provisioning complete. MongoDB 8.2.5 should be active on port 27017."
