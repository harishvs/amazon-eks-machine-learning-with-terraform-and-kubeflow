# Diagnostic Scripts for Neuron/EFA/NCCL Issues

## Scripts Overview

### Environment Variable Checks
- **`check_pod_env_vars.sh`** - Checks if EFA/NCCL environment variables are set in pods

### Neuron Utilization Diagnostics  
- **`focused_neuron_check.sh`** - Quick check of neuron utilization in both pods
- **`detailed_neuron_debug.sh`** - Comprehensive neuron utilization analysis
- **`diagnose_compilation_issue.sh`** - Checks if master node is stuck in compilation

### Network/Communication Diagnostics
- **`fix_nccl_communication.sh`** - Diagnoses NCCL communication issues between nodes
- **`check_placement_group.sh`** - Checks if instances are in placement groups

### General Node Diagnostics
- **`debug_trn2_node.sh`** - General trn2 node health check
- **`debug_master_neuron_utilization.sh`** - Specific master node neuron diagnostics
- **`quick_neuron_check.sh`** - Fast neuron status check

## Key Findings from Environment Variable Check

### ✅ Working (Already Set):
- `FI_PROVIDER=efa`
- `FI_EFA_USE_DEVICE_RDMA=1` 
- `FI_EFA_FORK_SAFE=1`

### ❌ Missing (Need to be Set):
- `NCCL_PROTO=simple`
- `NCCL_ALGO=ring`
- `NCCL_DEBUG=INFO`
- `NCCL_SOCKET_IFNAME=^docker0,lo`
- `NCCL_NET_GDR_LEVEL=PHB`
- `NCCL_CROSS_NIC=1`
- `NCCL_COLLNET_ENABLE=1`
- `NCCL_TREE_THRESHOLD=0`

## Network Command Alternatives

Since `netstat` and `telnet` are not available in the pods, use these alternatives:

### Instead of `netstat -tlnp`:
```bash
# Option 1: Use ss (socket statistics)
kubectl exec <pod> -- ss -tlnp

# Option 2: Read /proc/net/tcp directly
kubectl exec <pod> -- cat /proc/net/tcp

# Option 3: Use lsof if available
kubectl exec <pod> -- lsof -i -P -n
```

### Instead of `telnet <host> <port>`:
```bash
# Option 1: Use nc (netcat)
kubectl exec <pod> -- nc -zv <host> <port>

# Option 2: Use bash built-in TCP test
kubectl exec <pod> -- timeout 5 bash -c "echo >/dev/tcp/<host>/<port>"

# Option 3: Use curl for HTTP ports
kubectl exec <pod> -- curl -v telnet://<host>:<port>
```

### Port 23456 Specific Check:
```bash
# Check if port 23456 is listening
kubectl exec <pod> -- ss -tlnp | grep 23456

# Test connection to port 23456
kubectl exec <pod> -- timeout 5 bash -c "echo >/dev/tcp/<target-pod>/23456"
```

## Next Steps

1. **Apply Terraform Changes**: The `user_data.sh` will set the missing NCCL environment variables
2. **Restart Training Job**: New pods will pick up the environment variables
3. **Re-run Diagnostics**: Verify all variables are set and NCCL communication works

## Root Cause Summary

The NCCL communication timeout issue is caused by:
1. **Missing NCCL environment variables** in the pods (found by diagnostics)
2. **EFA configuration** needs optimization (addressed in terraform changes)
3. **Security group rules** need to allow inter-node communication (fixed in mng.tf)

The terraform changes address the infrastructure level, and restarting the training job will pick up the new environment variables.