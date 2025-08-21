#!/bin/bash

# EFA Connectivity Check Script for trn2 nodes
# This script only performs checks without installing or modifying anything

set -e

echo "=========================================="
echo "EFA Connectivity Check for trn2 Nodes"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

echo "1. Checking EFA driver installation..."
if lsmod | grep -q efa; then
    print_status 0 "EFA driver is loaded"
    lsmod | grep efa
else
    print_status 1 "EFA driver is NOT loaded"
fi

echo ""
echo "2. Checking EFA devices..."
EFA_DEVICES=$(ls /sys/class/infiniband/ 2>/dev/null | grep -c efa || echo "0")
if [ "$EFA_DEVICES" -gt 0 ]; then
    print_status 0 "Found $EFA_DEVICES EFA device(s)"
    ls /sys/class/infiniband/
else
    print_status 1 "No EFA devices found"
fi

echo ""
echo "3. Checking libfabric and EFA provider..."
if command -v fi_info >/dev/null 2>&1; then
    print_status 0 "libfabric is installed"
    echo "EFA provider info:"
    fi_info -p efa 2>/dev/null || print_warning "EFA provider not available"
else
    print_status 1 "libfabric (fi_info) not found"
fi

echo ""
echo "4. Checking instance metadata..."
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unknown")
PLACEMENT_GROUP=$(curl -s http://169.254.169.254/latest/meta-data/placement/group-name 2>/dev/null || echo "none")

echo "Instance ID: $INSTANCE_ID"
echo "Instance Type: $INSTANCE_TYPE"
echo "Placement Group: $PLACEMENT_GROUP"

if [[ "$INSTANCE_TYPE" == trn2* ]]; then
    print_status 0 "Running on trn2 instance type"
else
    print_status 1 "NOT running on trn2 instance type"
fi

if [ "$PLACEMENT_GROUP" != "none" ]; then
    print_status 0 "Instance is in placement group: $PLACEMENT_GROUP"
else
    print_warning "Instance is NOT in a placement group (recommended for EFA)"
fi

echo ""
echo "5. Checking network interfaces..."
if [ "$EFA_INTERFACES" -gt 0 ]; then
    print_status 0 "Found $EFA_INTERFACES EFA network interface(s)"
    ip link show | grep efa
else
    print_status 1 "No EFA network interfaces found"
fiEFA_INTERFACES=$(ip link show | grep -c efa || echo "0")


echo ""
echo "6. Checking security groups..."
SECURITY_GROUPS=$(curl -s http://169.254.169.254/latest/meta-data/security-groups 2>/dev/null || echo "unknown")
echo "Security Groups: $SECURITY_GROUPS"

echo ""
echo "7. Checking EFA connectivity tools availability..."
if command -v fi_pingpong >/dev/null 2>&1; then
    print_status 0 "fi_pingpong is available for connectivity testing"
    echo "To test connectivity between nodes:"
    echo "  On node 1: fi_pingpong -p efa &"
    echo "  On node 2: fi_pingpong -p efa <node1_ip>"
else
    print_status 1 "fi_pingpong not available for connectivity testing"
fi

echo ""
echo "8. Basic EFA functionality test..."
if command -v fi_info >/dev/null 2>&1; then
    echo "Testing EFA provider capabilities..."
    fi_info -p efa -t FI_EP_RDM 2>/dev/null && print_status 0 "EFA RDM endpoint test passed" || print_status 1 "EFA RDM endpoint test failed"
else
    print_warning "fi_info not available for EFA capability testing"
fi

echo ""
echo "9. Checking for common issues..."

# Check if running in container/pod
if [ -f /.dockerenv ] || [ -n "${KUBERNETES_SERVICE_HOST}" ]; then
    print_warning "Running in container/pod - ensure EFA devices are mounted"
    echo "Check: ls -la /dev/infiniband/"
fi

# Check huge pages
HUGEPAGES=$(cat /proc/meminfo | grep HugePages_Total | awk '{print $2}')
if [ "$HUGEPAGES" -gt 0 ]; then
    print_status 0 "Huge pages configured: $HUGEPAGES"
else
    print_warning "No huge pages configured (may impact performance)"
fi

echo ""
echo "=========================================="
echo "EFA Check Complete"
echo "=========================================="
echo ""
echo "Next steps if issues found:"
echo "1. Install EFA driver: sudo yum install -y efa-installer"
echo "2. Install libfabric: sudo yum install -y libfabric libfabric-devel"
echo "3. Verify security group allows all traffic from itself"
echo "4. Ensure instances are in same placement group"
echo "5. Check EFA interfaces: sudo /opt/amazon/efa/bin/fi_info -p efa"