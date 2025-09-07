#!/bin/bash
# Configure passwordless sudo for Ansible automation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Configure Passwordless Sudo for Ansible ==="
echo
echo -e "${YELLOW}This script needs to be run with sudo privileges${NC}"
echo "It will configure passwordless sudo for the current user ($USER)"
echo

# Check if ansible key is already configured
if [ -f ~/.ssh/authorized_keys ] && grep -q "ansible" ~/.ssh/authorized_keys; then
    echo -e "${GREEN}✓${NC} Ansible SSH key is already authorized"
fi

# Check if ansible private key exists locally
if [ -f ~/.ssh/ansible_ed25519 ]; then
    echo -e "${GREEN}✓${NC} Ansible private key found locally"
    echo "  This node can also act as a control node if needed"
fi

echo

# Check if user is in wheel group
if groups | grep -q wheel; then
    echo -e "${GREEN}✓${NC} User $USER is in wheel group"
else
    echo -e "${RED}✗${NC} User $USER is NOT in wheel group"
    echo "Add user to wheel group first:"
    echo "  sudo usermod -aG wheel $USER"
    echo "Then logout and login again"
    exit 1
fi

# Create the sudoers.d file content
SUDOERS_FILE="/etc/sudoers.d/ansible-$USER"
SUDOERS_CONTENT="# Ansible automation passwordless sudo for $USER
$USER ALL=(ALL) NOPASSWD: ALL"

echo
echo "The following configuration will be added:"
echo "----------------------------------------"
echo "$SUDOERS_CONTENT"
echo "----------------------------------------"
echo
echo "File location: $SUDOERS_FILE"
echo

# Create a script that needs to be run with sudo
cat > /tmp/configure-sudo.sh << EOF
#!/bin/bash
# This script must be run with sudo

# Write the sudoers configuration
echo "$SUDOERS_CONTENT" > $SUDOERS_FILE

# Set correct permissions
chmod 440 $SUDOERS_FILE

# Validate the sudoers file
if visudo -c -f $SUDOERS_FILE; then
    echo -e "\033[0;32m✓\033[0m Sudoers file validated successfully"
else
    echo -e "\033[0;31m✗\033[0m Sudoers file validation failed"
    rm -f $SUDOERS_FILE
    exit 1
fi

echo -e "\033[0;32m✓\033[0m Passwordless sudo configured for $USER"
EOF

chmod +x /tmp/configure-sudo.sh

echo -e "${YELLOW}Run this command to configure passwordless sudo:${NC}"
echo
echo "  sudo /tmp/configure-sudo.sh"
echo
echo "After running the command above:"
echo "1. Test with: sudo -n true && echo 'Success' || echo 'Failed'"
echo "2. Run: ./scripts/setup/ansible-readiness-check.sh"

echo
echo "=== Alternative Manual Method ==="
echo "If you prefer to do it manually:"
echo "1. Run: sudo visudo -f /etc/sudoers.d/ansible-$USER"
echo "2. Add this line:"
echo "   $USER ALL=(ALL) NOPASSWD: ALL"
echo "3. Save and exit"