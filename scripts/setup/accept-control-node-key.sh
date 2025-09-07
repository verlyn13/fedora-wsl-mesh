#!/bin/bash
# Accept the Ansible control node's SSH key

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Accept Control Node SSH Key ==="
echo
echo "This script will authorize the Ansible control node (hetzner-hq) to access this WSL node."
echo

# Ensure SSH directory exists with correct permissions
echo "Setting up SSH directory..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create authorized_keys if it doesn't exist
if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    chmod 644 ~/.ssh/authorized_keys
    echo "Created ~/.ssh/authorized_keys"
fi

# Check if local ansible key exists
if [ -f ~/.ssh/ansible_ed25519.pub ]; then
    echo -e "${GREEN}✓${NC} Found local Ansible public key at ~/.ssh/ansible_ed25519.pub"
    
    ANSIBLE_KEY=$(cat ~/.ssh/ansible_ed25519.pub)
    
    # Check if this key is already authorized
    if grep -q "$ANSIBLE_KEY" ~/.ssh/authorized_keys; then
        echo -e "${GREEN}✓${NC} This Ansible key is already in authorized_keys"
    else
        echo "Adding local Ansible key to authorized_keys..."
        echo "$ANSIBLE_KEY" >> ~/.ssh/authorized_keys
        echo -e "${GREEN}✓${NC} Local Ansible key added to authorized_keys"
    fi
    
    echo
    echo "Key details:"
    echo "  Type: $(echo $ANSIBLE_KEY | awk '{print $1}')"
    echo "  Comment: $(echo $ANSIBLE_KEY | awk '{print $3}')"
    echo "  Fingerprint: $(ssh-keygen -lf ~/.ssh/ansible_ed25519.pub | awk '{print $2}')"
    
    # Set correct permissions on private key
    if [ -f ~/.ssh/ansible_ed25519 ]; then
        chmod 600 ~/.ssh/ansible_ed25519
        echo -e "${GREEN}✓${NC} Private key permissions set to 600"
    fi
else
    echo -e "${YELLOW}⚠${NC} No local Ansible key found at ~/.ssh/ansible_ed25519.pub"
fi

# The control node's Ansible SSH public key
# This should be obtained from the control node at ~/.ssh/ansible_ed25519.pub
echo
echo -e "${YELLOW}Option 1: Automatic (if control node is accessible)${NC}"
echo "Attempting to fetch key from control node..."

# Try to get the key from the control node
if tailscale ping -c 1 hetzner-hq &> /dev/null; then
    echo "Control node is reachable. Fetching Ansible public key..."
    
    # Note: This requires the control node to already have the key generated
    # The control node admin should run: ssh-keygen -t ed25519 -f ~/.ssh/ansible_ed25519 -C "ansible@hetzner-hq"
    
    echo
    echo "Run this command on the control node (hetzner-hq) to display the key:"
    echo -e "${YELLOW}cat ~/.ssh/ansible_ed25519.pub${NC}"
    echo
    echo "Then paste it here (or press Ctrl+C to cancel):"
    read -r ANSIBLE_KEY
    
    if [ -n "$ANSIBLE_KEY" ]; then
        # Check if key already exists
        if grep -q "$ANSIBLE_KEY" ~/.ssh/authorized_keys; then
            echo -e "${GREEN}✓${NC} This key is already authorized"
        else
            echo "$ANSIBLE_KEY" >> ~/.ssh/authorized_keys
            echo -e "${GREEN}✓${NC} Key added to authorized_keys"
        fi
    else
        echo -e "${RED}No key provided${NC}"
    fi
else
    echo -e "${RED}Control node not reachable via Tailscale${NC}"
    echo
    echo -e "${YELLOW}Option 2: Manual Setup${NC}"
    echo "1. On the control node (hetzner-hq), generate the Ansible key if not exists:"
    echo "   ssh-keygen -t ed25519 -f ~/.ssh/ansible_ed25519 -C 'ansible@hetzner-hq'"
    echo
    echo "2. Display the public key on control node:"
    echo "   cat ~/.ssh/ansible_ed25519.pub"
    echo
    echo "3. Copy the key and run this command on WSL node:"
    echo "   echo 'PASTE_KEY_HERE' >> ~/.ssh/authorized_keys"
fi

echo
echo -e "${YELLOW}Option 3: Use ssh-copy-id from control node${NC}"
echo "On the control node, run:"
echo "ssh-copy-id -i ~/.ssh/ansible_ed25519.pub verlyn13@wsl-fedora-kbc"
echo "or"
echo "ssh-copy-id -i ~/.ssh/ansible_ed25519.pub verlyn13@$(tailscale ip -4 2>/dev/null || echo '100.88.131.44')"

echo
echo "=== Current Authorized Keys ==="
if [ -f ~/.ssh/authorized_keys ]; then
    KEY_COUNT=$(wc -l < ~/.ssh/authorized_keys)
    echo "Total keys: $KEY_COUNT"
    
    if grep -q "ansible" ~/.ssh/authorized_keys; then
        echo -e "${GREEN}✓${NC} Found key with 'ansible' identifier"
    else
        echo -e "${YELLOW}⚠${NC} No key with 'ansible' identifier found"
    fi
    
    echo
    echo "Keys present:"
    awk '{print "  - " substr($NF, 1, 50) "..."}' ~/.ssh/authorized_keys
else
    echo "No authorized_keys file exists yet"
fi

echo
echo "=== Next Steps ==="
echo "1. Ensure the control node's Ansible key is in ~/.ssh/authorized_keys"
echo "2. Test from control node: ssh -i ~/.ssh/ansible_ed25519 verlyn13@wsl-fedora-kbc"
echo "3. Run: ./scripts/setup/configure-passwordless-sudo.sh"