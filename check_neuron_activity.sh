#!/bin/bash

echo "=== Checking neuron activity on master node ==="
kubectl exec pytorchjob-nxd-llama31-8b-master-0 -- timeout 10 neuron-top --no-clear

echo -e "\n=== Checking neuron activity on worker node ==="
kubectl exec pytorchjob-nxd-llama31-8b-worker-0 -- timeout 10 neuron-top --no-clear

echo -e "\n=== Checking process activity on both nodes ==="
echo "Master node processes:"
kubectl exec pytorchjob-nxd-llama31-8b-master-0 -- ps aux | grep python

echo -e "\nWorker node processes:"
kubectl exec pytorchjob-nxd-llama31-8b-worker-0 -- ps aux | grep python