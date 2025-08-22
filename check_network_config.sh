#!/bin/bash

echo "=== NETWORK CONFIGURATION DIAGNOSIS ==="

MASTER_POD="pytorchjob-nxd-llama31-8b-master-0"
WORKER_POD="pytorchjob-nxd-llama31-8b-worker-0"
NAMESPACE="kubeflow-user-example-com"

echo "1. Getting pod IP addresses..."
MASTER_IP=$(kubectl get pod $MASTER_POD -n $NAMESPACE -o jsonpath='{.status.podIP}')
WORKER_IP=$(kubectl get pod $WORKER_POD -n $NAMESPACE -o jsonpath='{.status.podIP}')

echo "Master pod IP: $MASTER_IP"
echo "Worker pod IP: $WORKER_IP"
echo ""

echo "2. Checking pod network details..."
echo "Master pod network info:"
kubectl get pod $MASTER_POD -n $NAMESPACE -o jsonpath='{.status.hostIP}' && echo " (host IP)"
kubectl get pod $MASTER_POD -n $NAMESPACE -o jsonpath='{.spec.nodeName}' && echo " (node name)"
echo ""

echo "Worker pod network info:"
kubectl get pod $WORKER_POD -n $NAMESPACE -o jsonpath='{.status.hostIP}' && echo " (host IP)"
kubectl get pod $WORKER_POD -n $NAMESPACE -o jsonpath='{.spec.nodeName}' && echo " (node name)"
echo ""

echo "3. Checking Kubernetes network policies..."
kubectl get networkpolicies -n $NAMESPACE
echo ""

echo "4. Testing basic connectivity with alternative methods..."
echo "Master pod can reach worker IP directly:"
kubectl exec $MASTER_POD -n $NAMESPACE -- timeout 5 bash -c "echo test | nc -w 3 $WORKER_IP 23456" 2>/dev/null && echo "SUCCESS" || echo "FAILED"
echo ""

echo "Worker pod can reach master IP directly:"
kubectl exec $WORKER_POD -n $NAMESPACE -- timeout 5 bash -c "echo test | nc -w 3 $MASTER_IP 23456" 2>/dev/null && echo "SUCCESS" || echo "FAILED"
echo ""

echo "5. Checking if pods are on same node or different nodes..."
MASTER_NODE=$(kubectl get pod $MASTER_POD -n $NAMESPACE -o jsonpath='{.spec.nodeName}')
WORKER_NODE=$(kubectl get pod $WORKER_POD -n $NAMESPACE -o jsonpath='{.spec.nodeName}')

if [ "$MASTER_NODE" = "$WORKER_NODE" ]; then
    echo "SAME NODE: Both pods on $MASTER_NODE - should use localhost communication"
else
    echo "DIFFERENT NODES: Master on $MASTER_NODE, Worker on $WORKER_NODE - requires inter-node networking"
fi
echo ""

echo "6. Checking EFA network interfaces in pods..."
echo "Master pod EFA network interfaces:"
kubectl exec $MASTER_POD -n $NAMESPACE -- ip addr show | grep -E "(efa|eth)" | head -5
echo ""

echo "Worker pod EFA network interfaces:"
kubectl exec $WORKER_POD -n $NAMESPACE -- ip addr show | grep -E "(efa|eth)" | head -5
echo ""

echo "=== SOLUTION RECOMMENDATIONS ==="
echo "Based on the diagnosis:"
echo "1. If SAME NODE: Check localhost/loopback communication"
echo "2. If DIFFERENT NODES: Check AWS Security Groups for inter-node communication"
echo "3. If NetworkPolicies exist: May need to allow communication between training pods"
echo "4. If EFA interfaces missing: EFA networking may not be properly configured"