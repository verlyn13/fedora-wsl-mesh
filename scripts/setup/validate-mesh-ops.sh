#!/bin/bash
# Phase 2.8: Validate mesh-ops user setup on WSL2 node

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MESH_USER="mesh-ops"
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

echo -e "${BLUE}=== Phase 2.8: Mesh-Ops User Validation for WSL2 ===${NC}"
echo

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to run warning test (non-critical)
run_warning_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Checking: $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${YELLOW}⚠${NC} (non-critical)"
        ((WARNINGS++))
        return 1
    fi
}

# Test 1: User exists
run_test "User exists" "id $MESH_USER"

# Test 2: Home directory exists
run_test "Home directory exists" "[ -d /home/$MESH_USER ]"

# Test 3: User can be switched to
run_test "Can switch to user" "sudo su - $MESH_USER -c 'echo test'"

# Test 4: SSH directory exists with correct permissions
run_test "SSH directory configured" "[ -d /home/$MESH_USER/.ssh ] && [ \$(stat -c %a /home/$MESH_USER/.ssh) = '700' ]"

# Test 5: Directory structure exists
echo -e "\n${BLUE}Directory Structure:${NC}"
for dir in .config .local/bin .local/share Projects Scripts .config/systemd/user; do
    run_test "  Directory: ~/$dir" "[ -d /home/$MESH_USER/$dir ]"
done

# Test 6: Configuration files exist
echo -e "\n${BLUE}Configuration Files:${NC}"
run_test "  .bash_profile exists" "[ -f /home/$MESH_USER/.bash_profile ]"
run_test "  .bashrc exists" "[ -f /home/$MESH_USER/.bashrc ]"
run_test "  mesh-ops config exists" "[ -f /home/$MESH_USER/.config/mesh-ops/config.yaml ]"

# Test 7: Sudo permissions
echo -e "\n${BLUE}Sudo Permissions:${NC}"
run_test "  Sudoers file exists" "[ -f /etc/sudoers.d/mesh-ops-wsl ]"
run_test "  Can run systemctl --user" "sudo -u $MESH_USER sudo systemctl --user status >/dev/null 2>&1 || [ \$? -eq 3 ]"
run_test "  Can run tailscale" "sudo -u $MESH_USER sudo tailscale version"

# Test 8: WSL-specific checks
echo -e "\n${BLUE}WSL-Specific Features:${NC}"
if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    run_test "  WSL2 environment detected" "true"
    run_test "  WSL interop available" "[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]"
else
    echo -e "  ${YELLOW}Not running in WSL2 - skipping WSL checks${NC}"
fi

# Test 9: Development tools (will be installed later)
echo -e "\n${BLUE}Development Tools (Phase 2.8+):${NC}"
sudo su - $MESH_USER -c '
    for tool in uv bun mise fish; do
        if command -v $tool &>/dev/null; then
            echo -e "  '"${GREEN}"'✓'"${NC}"' $tool installed"
        else
            echo -e "  '"${YELLOW}"'○'"${NC}"' $tool not yet installed"
        fi
    done
'

# Test 10: Network connectivity
echo -e "\n${BLUE}Network Connectivity:${NC}"
run_warning_test "  DNS resolution" "nslookup google.com"
run_warning_test "  Internet connectivity" "ping -c 1 8.8.8.8"

# Test 11: Mesh connectivity (if Tailscale is running)
echo -e "\n${BLUE}Mesh Network:${NC}"
if command -v tailscale &>/dev/null && tailscale status &>/dev/null; then
    for host in hetzner-hq laptop-hq; do
        run_warning_test "  Can ping $host" "tailscale ping -c 1 $host"
    done
else
    echo -e "  ${YELLOW}Tailscale not running - skipping mesh tests${NC}"
fi

# Summary
echo
echo -e "${BLUE}=== Validation Summary ===${NC}"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    echo -e "The mesh-ops user is ready for Phase 2.8 deployment."
    echo
    echo "Next steps:"
    echo "1. Install development tools: ./scripts/setup/install-mesh-ops-tools.sh"
    echo "2. Configure SSH keys for mesh-ops user"
    echo "3. Set up Syncthing and other services"
    exit 0
else
    echo
    echo -e "${RED}✗ Some tests failed. Please review and fix issues.${NC}"
    exit 1
fi