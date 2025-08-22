#!/bin/bash

echo "=== Detailed Neuron Utilization Debug ==="

MASTER_NODE="ip-192-168-252-239.ap-southeast-4.compute.internal"
WORKER_NODE="ip-192-168-243-241.ap-southeast-4.compute.internal"
MASTER_POD="pytorchjob-nxd-llama31-8b-master-0"
WORKER_POD="pytorchjob-nxd-llama31-8b-worker-0"

echo "Master node: $MASTER_NODE (16 neuron cores)"
echo "Worker node: $WORKER_NODE (16 neuron cores)"
echo "Master pod: $MASTER_POD"
echo "Worker pod: $WORKER_POD"
echo ""

# Check neuron utilization with correct command
echo "=== 1. Neuron Utilization Check ==="
echo "Master pod neuron activity:"
kubectl exec $MASTER_POD -n kubeflow-user-example-com -- timeout 10 neuron-top 2>/dev/null || echo "Failed to run neuron-top on master pod"
echo ""

echo "Worker pod neuron activity:"
kubectl exec $WORKER_POD -n kubeflow-user-example-com -- timeout 10 neuron-top 2>/dev/null || echo "Failed to run neuron-top on worker pod"
echo ""

# Check neuron-ls in both pods
echo "=== 2. Neuron Device Detection in Pods ==="
echo "Master pod neuron devices:"
kubectl exec $MASTER_POD -n kubeflow-user-example-com -- neuron-ls 2>/dev/null || echo "Failed to run neuron-ls on master pod"
echo ""

echo "Worker pod neuron devices:"
kubectl exec $WORKER_POD -n kubeflow-user-example-com -- neuron-ls 2>/dev/null || echo "Failed to run neuron-ls on worker pod"
echo ""

# Check processes in both pods
echo "=== 3. Process Analysis ==="
echo "Master pod Python processes:"
kubectl exec $MASTER_POD -n kubeflow-user-example-com -- ps aux | grep python | head -5
echo ""

echo "Worker pod Python processes:"
kubectl exec $WORKER_POD -n kubeflow-user-example-com -- ps aux | grep python | head -5
echo ""

# Check distributed training configuration
echo "=== 4. Distributed Training Environment ==="
echo "Master pod environment:"
kubectl exec $MASTER_POD -n kubeflow-user-example-com -- env | grep -E "(RANK|WORLD|MASTER|LOCAL|NEURON)" | sort
echo ""

echo "Worker pod environment:"
kubectl exec $WORKER_POD -n kubeflow-user-example-com -- env | grep -E "(RANK|WORLD|MASTER|LOCAL|NEURON)" | sort
echo ""

# Check recent logs for any neuron-related messages
echo "=== 5. Recent Pod Logs ==="
echo "Master pod recent logs (neuron-related):"
kubectl logs $MASTER_POD -n kubeflow-user-example-com --tail=50 | grep -i neuron | tail -10
echo ""

echo "Worker pod recent logs (neuron-related):"
kubectl logs $WORKER_POD -n kubeflow-user-example-com --tail=50 | grep -i neuron | tail -10
echo ""

# Check if training is actually running
echo "=== 6. Training Status Check ==="
echo "Master pod current activity:"
kubectl exec $MASTER_POD -n kubeflow-user-example-com -- ps aux | grep -E "(train|python)" | grep -v grep
echo ""

echo "Worker pod current activity:"
kubectl exec $WORKER_POD -n kubeflow-user-example-com -- ps aux | grep -E "(train|python)" | grep -v grep
echo ""