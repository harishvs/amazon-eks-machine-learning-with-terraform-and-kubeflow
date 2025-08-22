#!/bin/bash

echo "=== DIAGNOSING COMPILATION ISSUE ==="

MASTER_POD="pytorchjob-nxd-llama31-8b-master-0"
WORKER_POD="pytorchjob-nxd-llama31-8b-worker-0"
NAMESPACE="kubeflow-user-example-com"

echo "1. Checking recent logs for compilation status..."
echo "=== MASTER POD RECENT LOGS ==="
kubectl logs $MASTER_POD -n $NAMESPACE --tail=20 | grep -E "(Compiling|compiling|Compilation|compilation|Loading|loading|Step|step|Error|error)"
echo ""

echo "=== WORKER POD RECENT LOGS ==="
kubectl logs $WORKER_POD -n $NAMESPACE --tail=20 | grep -E "(Compiling|compiling|Compilation|compilation|Loading|loading|Step|step|Error|error)"
echo ""

echo "2. Checking for compilation cache and temporary files..."
echo "Master pod compilation status:"
kubectl exec $MASTER_POD -n $NAMESPACE -- find /tmp -name "*neuroncc*" -o -name "*compile*" | head -10
echo ""

echo "Worker pod compilation status:"
kubectl exec $WORKER_POD -n $NAMESPACE -- find /tmp -name "*neuroncc*" -o -name "*compile*" | head -10
echo ""

echo "3. Checking process states and CPU usage over time..."
echo "Master pod top processes:"
kubectl exec $MASTER_POD -n $NAMESPACE -- top -b -n 1 | head -15
echo ""

echo "Worker pod top processes:"
kubectl exec $WORKER_POD -n $NAMESPACE -- top -b -n 1 | head -15
echo ""

echo "4. Checking for any blocking operations..."
echo "Master pod process tree:"
kubectl exec $MASTER_POD -n $NAMESPACE -- pstree -p | head -10
echo ""

echo "5. Checking neuron compilation logs..."
echo "Master pod neuron compilation logs:"
kubectl exec $MASTER_POD -n $NAMESPACE -- find /tmp -name "*.log" -path "*neuron*" -exec tail -5 {} \; 2>/dev/null | head -20
echo ""

echo "=== SUMMARY ==="
echo "If master pod shows:"
echo "- Low CPU usage + models loaded but not running = Stuck in compilation"
echo "- High CPU usage + active neuron utilization = Training normally"
echo "- Compilation logs with errors = Compilation failed"
echo ""
echo "If worker pod shows high CPU + neuron utilization = Training is working"