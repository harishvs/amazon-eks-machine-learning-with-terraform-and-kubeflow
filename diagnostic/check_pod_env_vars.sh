#!/bin/bash

echo "=== Checking EFA/NCCL Environment Variables in Pods ==="

MASTER_POD="pytorchjob-nxd-llama31-8b-master-0"
WORKER_POD="pytorchjob-nxd-llama31-8b-worker-0"
NAMESPACE="kubeflow-user-example-com"

# List of required environment variables
REQUIRED_VARS=(
    "FI_PROVIDER"
    "FI_EFA_USE_DEVICE_RDMA"
    "FI_EFA_FORK_SAFE"
    "NCCL_PROTO"
    "NCCL_ALGO"
    "NCCL_DEBUG"
    "NCCL_SOCKET_IFNAME"
    "NCCL_NET_GDR_LEVEL"
    "NCCL_CROSS_NIC"
    "NCCL_COLLNET_ENABLE"
    "NCCL_TREE_THRESHOLD"
)

echo "Expected values:"
echo "FI_PROVIDER=efa"
echo "FI_EFA_USE_DEVICE_RDMA=1"
echo "FI_EFA_FORK_SAFE=1"
echo "NCCL_PROTO=simple"
echo "NCCL_ALGO=ring"
echo "NCCL_DEBUG=INFO"
echo "NCCL_SOCKET_IFNAME=^docker0,lo"
echo "NCCL_NET_GDR_LEVEL=PHB"
echo "NCCL_CROSS_NIC=1"
echo "NCCL_COLLNET_ENABLE=1"
echo "NCCL_TREE_THRESHOLD=0"
echo ""

check_pod_vars() {
    local pod_name=$1
    local pod_type=$2
    
    echo "=== $pod_type POD: $pod_name ==="
    
    for var in "${REQUIRED_VARS[@]}"; do
        value=$(kubectl exec $pod_name -n $NAMESPACE -- printenv $var 2>/dev/null || echo "NOT_SET")
        if [ "$value" = "NOT_SET" ]; then
            echo "❌ $var: NOT SET"
        else
            echo "✅ $var: $value"
        fi
    done
    echo ""
}

# Check master pod
check_pod_vars $MASTER_POD "MASTER"

# Check worker pod  
check_pod_vars $WORKER_POD "WORKER"

echo "=== Summary ==="
echo "If variables show 'NOT SET', they need to be configured in:"
echo "1. Pod environment variables (in the training job YAML)"
echo "2. Node-level /etc/environment (via user_data.sh)"
echo "3. Container runtime environment"
echo ""
echo "Next steps:"
echo "1. Apply terraform changes to configure node-level environment"
echo "2. Restart training job to pick up new environment variables"
echo "3. Check if the variables are being overridden by the training job configuration"