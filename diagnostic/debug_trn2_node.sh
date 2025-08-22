#!/bin/bash

echo "=== Checking Kubernetes nodes ==="
kubectl get nodes -o wide

echo -e "\n=== Checking node labels and taints ==="
kubectl get nodes --show-labels | grep trn2

echo -e "\n=== Checking neuron device plugin pods ==="
kubectl get pods -n kube-system | grep neuron

echo -e "\n=== Checking for any failed pods on trn2 nodes ==="
kubectl get pods --all-namespaces --field-selector spec.nodeName=$(kubectl get nodes | grep trn2 | head -1 | awk '{print $1}') | grep -v Running

echo -e "\n=== Checking neuron-ls on each trn2 node ==="
for node in $(kubectl get nodes | grep trn2 | awk '{print $1}'); do
    echo "--- Node: $node ---"
    kubectl debug node/$node -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host neuron-ls
done