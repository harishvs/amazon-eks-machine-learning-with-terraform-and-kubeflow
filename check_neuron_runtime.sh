#!/bin/bash

echo "=== Checking neuron-rtd service status on all trn2 nodes ==="
for node in $(kubectl get nodes | grep trn2 | awk '{print $1}'); do
    echo "--- Node: $node ---"
    kubectl debug node/$node -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host systemctl status neuron-rtd
    echo ""
done

echo -e "\n=== Checking for neuron driver issues ==="
for node in $(kubectl get nodes | grep trn2 | awk '{print $1}'); do
    echo "--- Node: $node ---"
    kubectl debug node/$node -it --image=public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04 -- chroot /host dmesg | grep -i neuron | tail -10
    echo ""
done