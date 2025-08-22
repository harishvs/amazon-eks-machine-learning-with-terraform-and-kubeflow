#!/bin/bash

echo "=== Focused Neuron Utilization Check ==="

MASTER_POD="pytorchjob-nxd-llama31-8b-master-0"
WORKER_POD="pytorchjob-nxd-llama31-8b-worker-0"
NAMESPACE="kubeflow-user-example-com"

echo "1. Checking neuron-ls output in both pods..."
echo "Master pod neuron devices:"
kubectl exec $MASTER_POD -n $NAMESPACE -- neuron-ls 2>/dev/null || echo "Failed to run neuron-ls on master pod"
echo ""

echo "Worker pod neuron devices:"
kubectl exec $WORKER_POD -n $NAMESPACE -- neuron-ls 2>/dev/null || echo "Failed to run neuron-ls on worker pod"
echo ""

echo "2. Checking neuron-monitor output..."
echo "Master pod neuron monitor:"
kubectl exec $MASTER_POD -n $NAMESPACE -- timeout 5 neuron-monitor 2>/dev/null || echo "Failed to run neuron-monitor on master pod"
echo ""

echo "Worker pod neuron monitor:"
kubectl exec $WORKER_POD -n $NAMESPACE -- timeout 5 neuron-monitor 2>/dev/null || echo "Failed to run neuron-monitor on worker pod"
echo ""

echo "3. Checking main training processes..."
echo "Master pod main processes:"
kubectl exec $MASTER_POD -n $NAMESPACE -- ps aux | grep -E "(train|python.*py)" | grep -v "compile_worker" | head -5
echo ""

echo "Worker pod main processes:"
kubectl exec $WORKER_POD -n $NAMESPACE -- ps aux | grep -E "(train|python.*py)" | grep -v "compile_worker" | head -5
echo ""

echo "4. Checking distributed training environment variables..."
echo "Master pod distributed training vars:"
kubectl exec $MASTER_POD -n $NAMESPACE -- env | grep -E "(RANK|WORLD_SIZE|MASTER_ADDR|MASTER_PORT|LOCAL_RANK|NODE_RANK)" | sort
echo ""

echo "Worker pod distributed training vars:"
kubectl exec $WORKER_POD -n $NAMESPACE -- env | grep -E "(RANK|WORLD_SIZE|MASTER_ADDR|MASTER_PORT|LOCAL_RANK|NODE_RANK)" | sort
echo ""

echo "5. Checking if neuron runtime is accessible..."
echo "Master pod neuron runtime check:"
kubectl exec $MASTER_POD -n $NAMESPACE -- python3 -c "import torch_neuronx; print('NeuronX available')" 2>/dev/null || echo "NeuronX not accessible"
echo ""

echo "Worker pod neuron runtime check:"
kubectl exec $WORKER_POD -n $NAMESPACE -- python3 -c "import torch_neuronx; print('NeuronX available')" 2>/dev/null || echo "NeuronX not accessible"
echo ""