#!/bin/bash

# EFA and NCCL configuration for trn2 instances
set -e

# Configure EFA
echo "Configuring EFA..."

# Set EFA environment variables with fallback support
cat >> /etc/environment << 'EOF'
FI_PROVIDER=efa
FI_EFA_USE_DEVICE_RDMA=1
FI_EFA_FORK_SAFE=1
NCCL_PROTO=simple
NCCL_ALGO=ring
NCCL_DEBUG=INFO
NCCL_SOCKET_IFNAME=^docker0,lo
NCCL_NET_GDR_LEVEL=PHB
NCCL_CROSS_NIC=1
NCCL_COLLNET_ENABLE=1
NCCL_TREE_THRESHOLD=0
# Allow fallback to TCP for bootstrap
NCCL_IB_DISABLE=0
NCCL_NET=IB,Socket
# Increase timeout for distributed training
NCCL_TIMEOUT=1800
NCCL_BLOCKING_WAIT=1
EOF

# Configure network settings for EFA
echo "Configuring network settings..."

# Increase network buffer sizes
cat >> /etc/sysctl.conf << 'EOF'
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 30000
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
# Allow pod-to-pod communication
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl settings
sysctl -p

# Configure EFA interfaces
echo "Setting up EFA interfaces..."

# Get the number of EFA interfaces
EFA_INTERFACES=$(ls /sys/class/infiniband/ 2>/dev/null | wc -l)
echo "Found $EFA_INTERFACES EFA interfaces"

# Configure each EFA interface
for i in $(seq 0 $((EFA_INTERFACES-1))); do
    if [ -d "/sys/class/infiniband/rdmap$i" ]; then
        echo "Configuring EFA interface rdmap$i"
        # Set interface up
        ip link set dev rdmap$i up || true
    fi
done

# Configure hugepages for better performance
echo "Configuring hugepages..."
echo 1024 > /proc/sys/vm/nr_hugepages

# Ensure EFA kernel module is loaded
echo "Loading EFA kernel modules..."
modprobe ib_uverbs || true
modprobe rdma_ucm || true

# Join the EKS cluster - THIS IS ESSENTIAL FOR MANAGED NODE GROUPS
echo "Joining EKS cluster..."
/etc/eks/bootstrap.sh ${cluster_name} \
    --container-runtime containerd \
    --kubelet-extra-args '--node-labels=aws.amazon.com/efa=true,aws.amazon.com/neuron=true --max-pods=110'

echo "EFA and NCCL configuration completed"

# Restart kubelet to ensure all settings are applied
systemctl restart kubelet

echo "Node bootstrap completed successfully"