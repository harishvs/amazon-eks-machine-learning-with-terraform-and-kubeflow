#!/bin/bash

# Debug script for master node neuron utilization issue
# Master node: ip-192-168-252-239.ap-southeast-4.compute.internal
# Worker node: ip-192-168-243-241.ap-southeast-4.compute.internal

MASTER_NODE="ip-192-168-252-239.ap-southeast-4.compute.internal"
WORKER_NODE="ip-192-168-243-241.ap-southeast-4.compute.internal"

echo "=== DEBUGGING MASTER NODE NEURON UTILIZATION ISSUE ==="
echo "Master node: $MASTER_NODE"
echo "Worker node: $WORKER_NODE"
echo ""

# Check if nodes exist and are ready
echo "=== 1. Node Status Check ==="
kubectl get nodes $MASTER_NODE $WORKER_NODE -o wide
echo ""

# Check pod distribution
echo "=== 2. Pod Distribution on Nodes ==="
echo "Pods on master node:"
kubectl get pods --all-namespaces --field-selector spec.nodeName=$MASTER_NODE
echo ""
echo "Pods on worker node:"
kubectl get pods --all-namespaces --field-selector spec.nodeName=$WORKER_NODE
echo ""

# Check neuron device plugin status
echo "=== 3. Neuron Device Plugin Status ==="
kubectl get pods -n kube-system | grep neuron
echo ""

# Check neuron resources on both nodes
echo "=== 4. Neuron Resource Allocation ==="
echo "Master node resources:"
kubectl describe node $MASTER_NODE | grep -A 10 -B 5 "aws.amazon.com/neuron"
echo ""
echo "Worker node resources:"
kubectl describe node $WORKER_NODE | grep -A 10 -B 5 "aws.amazon.com/neuron"
echo ""

# Check neuron-ls on both nodes
echo "=== 5. Neuron Device Detection ==="
echo "Master node neuron devices:"
kubectl debug node/$MASTER_NODE -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host neuron-ls
echo ""
echo "Worker node neuron devices:"
kubectl debug node/$WORKER_NODE -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host neuron-ls
echo ""

# Check neuron runtime daemon
echo "=== 6. Neuron Runtime Daemon Status ==="
echo "Master node neuron-rtd:"
kubectl debug node/$MASTER_NODE -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host systemctl status neuron-rtd
echo ""
echo "Worker node neuron-rtd:"
kubectl debug node/$WORKER_NODE -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host systemctl status neuron-rtd
echo ""#
 Check training job pods specifically
echo "=== 7. Training Job Pod Analysis ==="
echo "Looking for training job pods..."
kubectl get pods --all-namespaces | grep -E "(master|worker|train)"
echo ""

# Check if master pod is actually using neuron
echo "=== 8. Neuron Utilization Check ==="
MASTER_POD=$(kubectl get pods --all-namespaces --field-selector spec.nodeName=$MASTER_NODE | grep master | head -1 | awk '{print $2}')
WORKER_POD=$(kubectl get pods --all-namespaces --field-selector spec.nodeName=$WORKER_NODE | grep worker | head -1 | awk '{print $2}')

if [ ! -z "$MASTER_POD" ]; then
    echo "Master pod: $MASTER_POD"
    echo "Checking neuron-top on master pod:"
    kubectl exec $MASTER_POD -- timeout 5 neuron-top --no-clear || echo "Failed to run neuron-top on master pod"
    echo ""
    
    echo "Checking processes in master pod:"
    kubectl exec $MASTER_POD -- ps aux | grep -E "(python|torch|neuron)" | head -10
    echo ""
    
    echo "Checking environment variables in master pod:"
    kubectl exec $MASTER_POD -- env | grep -E "(NEURON|RANK|WORLD|LOCAL)" | sort
    echo ""
fi

if [ ! -z "$WORKER_POD" ]; then
    echo "Worker pod: $WORKER_POD"
    echo "Checking neuron-top on worker pod:"
    kubectl exec $WORKER_POD -- timeout 5 neuron-top --no-clear || echo "Failed to run neuron-top on worker pod"
    echo ""
    
    echo "Checking processes in worker pod:"
    kubectl exec $WORKER_POD -- ps aux | grep -E "(python|torch|neuron)" | head -10
    echo ""
fi

# Check for any errors in pod logs
echo "=== 9. Pod Logs Analysis ==="
if [ ! -z "$MASTER_POD" ]; then
    echo "Recent master pod logs (last 20 lines):"
    kubectl logs $MASTER_POD --tail=20 | grep -E "(error|Error|ERROR|neuron|Neuron|NEURON)" || echo "No neuron-related errors found"
    echo ""
fi

if [ ! -z "$WORKER_POD" ]; then
    echo "Recent worker pod logs (last 20 lines):"
    kubectl logs $WORKER_POD --tail=20 | grep -E "(error|Error|ERROR|neuron|Neuron|NEURON)" || echo "No neuron-related errors found"
    echo ""
fi

# Check node-level neuron processes
echo "=== 10. Node-Level Neuron Process Check ==="
echo "Master node neuron processes:"
kubectl debug node/$MASTER_NODE -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host ps aux | grep -E "(neuron|nrt)" | grep -v grep
echo ""

echo "Worker node neuron processes:"
kubectl debug node/$WORKER_NODE -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host ps aux | grep -E "(neuron|nrt)" | grep -v grep
echo ""

# Check for distributed training configuration issues
echo "=== 11. Distributed Training Configuration ==="
echo "Checking for distributed training environment variables and configuration..."
if [ ! -z "$MASTER_POD" ]; then
    echo "Master pod distributed training config:"
    kubectl exec $MASTER_POD -- env | grep -E "(MASTER|RANK|WORLD_SIZE|LOCAL_RANK|NODE_RANK|NCCL|GLOO)" | sort
    echo ""
fi

if [ ! -z "$WORKER_POD" ]; then
    echo "Worker pod distributed training config:"
    kubectl exec $WORKER_POD -- env | grep -E "(MASTER|RANK|WORLD_SIZE|LOCAL_RANK|NODE_RANK|NCCL|GLOO)" | sort
    echo ""
fi

echo "=== DEBUGGING COMPLETE ==="
echo "Summary of potential issues to investigate:"
echo "1. Check if master node has neuron devices properly detected"
echo "2. Verify neuron-rtd service is running on master node"
echo "3. Check if master pod is configured for distributed training correctly"
echo "4. Verify neuron device plugin is allocating resources to master pod"
echo "5. Check for any neuron driver or runtime errors on master node"