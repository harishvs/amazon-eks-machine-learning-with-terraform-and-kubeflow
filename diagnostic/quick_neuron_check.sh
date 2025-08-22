#!/bin/bash

echo "=== Quick Neuron Utilization Check ==="

# Find training pods
echo "1. Finding training job pods..."
kubectl get pods --all-namespaces | grep -E "(master|worker|train|pytorch)"

echo -e "\n2. Checking neuron activity on master and worker pods..."

# Try to find the actual pod names
MASTER_POD=$(kubectl get pods --all-namespaces | grep master | head -1 | awk '{print $2}')
WORKER_POD=$(kubectl get pods --all-namespaces | grep worker | head -1 | awk '{print $2}')

if [ ! -z "$MASTER_POD" ]; then
    echo "Master pod ($MASTER_POD) neuron activity:"
    kubectl exec $MASTER_POD -- neuron-top --no-clear | head -20 2>/dev/null || echo "Cannot access neuron-top on master pod"
else
    echo "No master pod found"
fi

echo ""

if [ ! -z "$WORKER_POD" ]; then
    echo "Worker pod ($WORKER_POD) neuron activity:"
    kubectl exec $WORKER_POD -- neuron-top --no-clear | head -20 2>/dev/null || echo "Cannot access neuron-top on worker pod"
else
    echo "No worker pod found"
fi

echo -e "\n3. Checking node neuron resources..."
kubectl get nodes -o custom-columns="NAME:.metadata.name,NEURON:.status.allocatable.aws\.amazon\.com/neuron"