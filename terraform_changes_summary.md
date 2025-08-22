# Terraform Changes Summary for NCCL Communication Fix

## Changes Made to Fix Master Node Neuron Utilization Issue

### Root Cause
The master node had no neuron core utilization because of **NCCL communication timeouts** between the master and worker nodes. The diagnostic showed:
- Master node: Stuck waiting for NCCL communication (low CPU usage)
- Worker node: Training normally (high CPU usage, neuron cores active)
- Network connectivity issues between pods

### Changes Made

#### 1. **mng.tf** - Enhanced EFA Configuration
- **Added Placement Group**: Created `aws_placement_group.trn2_cluster_pg` for optimal EFA performance
- **Enhanced Security Group**: Added specific rules for NCCL communication (port 23456) and EFA traffic
- **Fixed Network Interfaces**: Properly configured primary interface (device_index 0) and EFA interfaces (1-8)
- **Subnet Optimization**: Limited node placement to single AZ (`neuron_az`) for placement group effectiveness
- **User Data**: Added EFA and NCCL configuration script

#### 2. **terraform.tfvars** - EFA Enablement
- **Added EFA Configuration**: `efa_enabled = { "trn2.48xlarge" = 8 }` to enable 8 EFA interfaces per instance

#### 3. **user_data.sh** - EFA/NCCL Setup Script
- **EFA Environment Variables**: Configured FI_PROVIDER, FI_EFA_USE_DEVICE_RDMA, etc.
- **NCCL Settings**: Optimized NCCL for EFA communication
- **Network Tuning**: Increased buffer sizes and configured TCP settings
- **Hugepages**: Configured for better performance
- **Systemd Service**: Automatic EFA interface configuration on boot

### Key Improvements

1. **Placement Group**: Ensures instances are physically close for optimal EFA performance
2. **Enhanced Security Rules**: Explicit rules for NCCL (port 23456) and EFA traffic
3. **Proper EFA Interface Configuration**: Fixed device indexing and network card assignment
4. **Single AZ Deployment**: All nodes in same AZ for placement group effectiveness
5. **Optimized NCCL Settings**: Environment variables for better distributed training

### Next Steps

1. **Apply Terraform Changes**:
   ```bash
   cd eks-cluster/terraform/aws-eks-cluster-and-nodegroup/
   terraform plan
   terraform apply
   ```

2. **Restart Training Job** (after infrastructure update):
   ```bash
   kubectl delete pytorchjob pytorchjob-nxd-llama31-8b -n kubeflow-user-example-com
   # Then restart your training job
   ```

3. **Verify EFA Configuration**:
   ```bash
   # Check EFA interfaces in pods
   kubectl exec <pod-name> -n kubeflow-user-example-com -- ls -la /dev/infiniband/
   
   # Check NCCL environment variables
   kubectl exec <pod-name> -n kubeflow-user-example-com -- env | grep -E "(NCCL|FI_)"
   ```

4. **Monitor Neuron Utilization**:
   ```bash
   # Run the diagnostic scripts to verify both nodes show neuron activity
   ./focused_neuron_check.sh
   ```

### Expected Results After Changes

- **Both master and worker nodes** should show neuron core utilization
- **NCCL communication** should establish successfully without timeouts
- **Training performance** should improve due to optimized EFA configuration
- **Network connectivity** between pods should work properly

### Troubleshooting

If issues persist after applying changes:

1. **Check Placement Group**: Ensure both instances are in the same placement group
2. **Verify EFA Interfaces**: Confirm EFA devices are present and configured
3. **Security Group Rules**: Ensure all necessary ports are open
4. **NCCL Logs**: Check for NCCL-related errors in pod logs
5. **Network Connectivity**: Test ping and port connectivity between pods

The main fix addresses the infrastructure-level networking and EFA configuration that was preventing proper NCCL communication between the distributed training nodes.