#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print error message and exit
error_exit() {
  echo -e "${RED}$1${NC}" >&2
  exit 1
}

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
  error_exit "This script must be run as root."
fi

# Get the full path of this script
SCRIPT_PATH=$(realpath $0)

# Update package list and upgrade packages
echo -e "${YELLOW}Updating package list and upgrading packages...${NC}"
sudo apt-get update -y && sudo apt-get upgrade -y || error_exit "Failed to update and upgrade packages."

# Install required dependencies
echo -e "${YELLOW}Installing required dependencies...${NC}"
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common make gnupg lsb-release || error_exit "Failed to install dependencies."

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || error_exit "Failed to add Docker GPG key."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repository."
sudo apt-get update -y || error_exit "Failed to update package list after adding Docker repository."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io || error_exit "Failed to install Docker."

# Start and enable Docker service
echo -e "${YELLOW}Starting and enabling Docker service...${NC}"
sudo systemctl start docker || error_exit "Failed to start Docker service."
sudo systemctl enable docker || error_exit "Failed to enable Docker service."

# Install Docker Compose (latest version)
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
echo -e "${YELLOW}Installing Docker Compose $DOCKER_COMPOSE_VERSION...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || error_exit "Failed to download Docker Compose."
sudo chmod +x /usr/local/bin/docker-compose || error_exit "Failed to make Docker Compose executable."

# Verify installations
echo -e "${YELLOW}Verifying installations...${NC}"
docker --version || error_exit "Docker installation verification failed."
docker-compose --version || error_exit "Docker Compose installation verification failed."
make --version || error_exit "Make installation verification failed."

# Create a systemd service for the initial setup
echo -e "${YELLOW}Creating systemd service for initial setup...${NC}"
sudo bash -c "cat <<EOF > /etc/systemd/system/initial-setup.service
[Unit]
Description=Initial Setup Service
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=true

[Install]
WantedBy=default.target
EOF" || error_exit "Failed to create systemd service file."

# Enable and start the systemd service
echo -e "${YELLOW}Enabling and starting the systemd service...${NC}"
sudo systemctl enable initial-setup.service || error_exit "Failed to enable systemd service."
sudo systemctl start initial-setup.service || error_exit "Failed to start systemd service."

echo -e "${GREEN}Initial system setup is complete. Please navigate to ~/homelab-setup and continue with the setup.${NC}"
