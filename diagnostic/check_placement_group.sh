#!/bin/bash

echo "=== Checking Current Placement Group Status ==="

# Get the node names for trn2 instances
echo "1. Finding trn2 nodes..."
TRN2_NODES=$(kubectl get nodes -l node.kubernetes.io/instance-type=trn2.48xlarge -o jsonpath='{.items[*].metadata.name}')

if [ -z "$TRN2_NODES" ]; then
    echo "No trn2.48xlarge nodes found"
    exit 1
fi

echo "Found trn2 nodes: $TRN2_NODES"
echo ""

# Get instance IDs for these nodes
echo "2. Getting instance IDs..."
for node in $TRN2_NODES; do
    INSTANCE_ID=$(kubectl get node $node -o jsonpath='{.spec.providerID}' | cut -d'/' -f5)
    echo "Node: $node -> Instance ID: $INSTANCE_ID"
    
    # Check placement group for this instance
    echo "Checking placement group for $INSTANCE_ID..."
    aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].Placement' --output table
    echo ""
done

echo "3. Listing all placement groups in the region..."
aws ec2 describe-placement-groups --query 'PlacementGroups[*].[GroupName,Strategy,State,GroupId]' --output table

echo ""
echo "=== Analysis ==="
echo "If instances show:"
echo "- Placement group name: They are already in a placement group"
echo "- No placement group: They need to be added to one"
echo "- Different placement groups: They should be in the same one for optimal EFA performance"