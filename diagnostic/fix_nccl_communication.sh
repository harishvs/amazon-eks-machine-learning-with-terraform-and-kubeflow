#!/bin/bash

echo "=== FIXING NCCL COMMUNICATION ISSUE ==="

MASTER_POD="pytorchjob-nxd-llama31-8b-master-0"
WORKER_POD="pytorchjob-nxd-llama31-8b-worker-0"
NAMESPACE="kubeflow-user-example-com"

echo "1. Checking network connectivity between pods..."
echo "Master pod can reach worker pod:"
# Try multiple methods since ping may not be available
kubectl exec $MASTER_POD -n $NAMESPACE -- timeout 5 bash -c "echo >/dev/tcp/$WORKER_POD/22" 2>/dev/null && echo "✅ Network connectivity OK" || \
kubectl exec $MASTER_POD -n $NAMESPACE -- nslookup $WORKER_POD 2>/dev/null >/dev/null && echo "✅ DNS resolution OK" || \
kubectl exec $MASTER_POD -n $NAMESPACE -- getent hosts $WORKER_POD 2>/dev/null >/dev/null && echo "✅ Host resolution OK" || \
echo "❌ Network connectivity test failed (ping/nc not available, trying DNS)"
echo ""

echo "Worker pod can reach master pod:"
kubectl exec $WORKER_POD -n $NAMESPACE -- timeout 5 bash -c "echo >/dev/tcp/$MASTER_POD/22" 2>/dev/null && echo "✅ Network connectivity OK" || \
kubectl exec $WORKER_POD -n $NAMESPACE -- nslookup $MASTER_POD 2>/dev/null >/dev/null && echo "✅ DNS resolution OK" || \
kubectl exec $WORKER_POD -n $NAMESPACE -- getent hosts $MASTER_POD 2>/dev/null >/dev/null && echo "✅ Host resolution OK" || \
echo "❌ Network connectivity test failed (ping/nc not available, trying DNS)"
echo ""

echo "2. Checking NCCL/communication ports..."
echo "Master pod listening ports (using ss instead of netstat):"
kubectl exec $MASTER_POD -n $NAMESPACE -- ss -tlnp | grep -E "(23456|LISTEN)" | head -5 2>/dev/null || \
kubectl exec $MASTER_POD -n $NAMESPACE -- cat /proc/net/tcp | head -5 2>/dev/null || \
echo "No network tools available in container"
echo ""

echo "Worker pod listening ports (using ss instead of netstat):"
kubectl exec $WORKER_POD -n $NAMESPACE -- ss -tlnp | grep -E "(23456|LISTEN)" | head -5 2>/dev/null || \
kubectl exec $WORKER_POD -n $NAMESPACE -- cat /proc/net/tcp | head -5 2>/dev/null || \
echo "No network tools available in container"
echo ""

echo "3. Checking EFA (Elastic Fabric Adapter) status..."
echo "Master pod EFA interfaces:"
kubectl exec $MASTER_POD -n $NAMESPACE -- ls -la /dev/infiniband/ 2>/dev/null || echo "No EFA devices found"
echo "Master pod EFA device info:"
kubectl exec $MASTER_POD -n $NAMESPACE -- ibv_devinfo 2>/dev/null | head -10 || echo "ibv_devinfo not available"
echo ""

echo "Worker pod EFA interfaces:"
kubectl exec $WORKER_POD -n $NAMESPACE -- ls -la /dev/infiniband/ 2>/dev/null || echo "No EFA devices found"
echo "Worker pod EFA device info:"
kubectl exec $WORKER_POD -n $NAMESPACE -- ibv_devinfo 2>/dev/null | head -10 || echo "ibv_devinfo not available"
echo ""

echo "EFA fabric connectivity test:"
echo "Master pod EFA fabric test:"
kubectl exec $MASTER_POD -n $NAMESPACE -- fi_info -p efa 2>/dev/null | head -5 || echo "fi_info not available - EFA may not be properly configured"
echo ""

echo "4. Checking for firewall/security group issues..."
echo "Master pod can connect to worker on port 23456:"
kubectl exec $MASTER_POD -n $NAMESPACE -- timeout 5 bash -c "echo >/dev/tcp/$WORKER_POD/23456" 2>/dev/null && echo "✅ Port 23456 accessible" || \
kubectl exec $MASTER_POD -n $NAMESPACE -- timeout 5 nc -zv $WORKER_POD 23456 2>/dev/null && echo "✅ Port 23456 accessible (nc)" || \
echo "❌ Port 23456 connection failed - checking if it's listening..."

# Check if port 23456 is actually listening on worker
echo "Checking if worker pod is listening on port 23456:"
kubectl exec $WORKER_POD -n $NAMESPACE -- ss -tlnp | grep 23456 || echo "Port 23456 not listening on worker pod"
echo ""

echo "5. Checking NCCL environment variables..."
echo "Master pod NCCL environment:"
kubectl exec $MASTER_POD -n $NAMESPACE -- env | grep -E "(NCCL|FI_|EFA)" | sort
echo ""

echo "Worker pod NCCL environment:"
kubectl exec $WORKER_POD -n $NAMESPACE -- env | grep -E "(NCCL|FI_|EFA)" | sort
echo ""

echo "=== DIAGNOSTIC RESULTS SUMMARY ==="
echo ""

# Store test results for final summary
NETWORK_CONNECTIVITY="UNKNOWN"
EFA_DEVICES="UNKNOWN" 
NCCL_PORT="UNKNOWN"
EFA_ENV_VARS="UNKNOWN"
NCCL_ENV_VARS="UNKNOWN"

# Check network connectivity result
if kubectl exec $MASTER_POD -n $NAMESPACE -- getent hosts $WORKER_POD >/dev/null 2>&1; then
    NETWORK_CONNECTIVITY="✅ PASS"
else
    NETWORK_CONNECTIVITY="❌ FAIL"
fi

# Check EFA devices
if kubectl exec $MASTER_POD -n $NAMESPACE -- ls /dev/infiniband/uverbs0 >/dev/null 2>&1; then
    EFA_DEVICES="✅ PASS"
else
    EFA_DEVICES="❌ FAIL"
fi

# Check NCCL port 23456
if kubectl exec $WORKER_POD -n $NAMESPACE -- ss -tlnp | grep -q 23456 2>/dev/null; then
    NCCL_PORT="✅ PASS"
else
    NCCL_PORT="❌ FAIL"
fi

# Check EFA environment variables
if kubectl exec $MASTER_POD -n $NAMESPACE -- printenv FI_PROVIDER 2>/dev/null | grep -q "efa"; then
    EFA_ENV_VARS="✅ PASS"
else
    EFA_ENV_VARS="❌ FAIL"
fi

# Check NCCL environment variables
if kubectl exec $MASTER_POD -n $NAMESPACE -- printenv NCCL_DEBUG >/dev/null 2>&1; then
    NCCL_ENV_VARS="✅ PASS"
else
    NCCL_ENV_VARS="❌ FAIL"
fi

echo "┌─────────────────────────────────────────────────────────┐"
echo "│                    TEST RESULTS                         │"
echo "├─────────────────────────────────────────────────────────┤"
printf "│ %-30s %s │\n" "Network Connectivity (DNS):" "$NETWORK_CONNECTIVITY"
printf "│ %-30s %s │\n" "EFA Devices Present:" "$EFA_DEVICES"
printf "│ %-30s %s │\n" "NCCL Port 23456 Listening:" "$NCCL_PORT"
printf "│ %-30s %s │\n" "EFA Environment Variables:" "$EFA_ENV_VARS"
printf "│ %-30s %s │\n" "NCCL Environment Variables:" "$NCCL_ENV_VARS"
echo "└─────────────────────────────────────────────────────────┘"

# Overall status
if [[ "$NETWORK_CONNECTIVITY" == *"✅"* && "$EFA_DEVICES" == *"✅"* && "$NCCL_PORT" == *"✅"* && "$EFA_ENV_VARS" == *"✅"* && "$NCCL_ENV_VARS" == *"✅"* ]]; then
    echo ""
    echo "🎉 OVERALL STATUS: ✅ ALL TESTS PASSED - NCCL should work properly"
    echo ""
elif [[ "$NCCL_ENV_VARS" == *"❌"* ]]; then
    echo ""
    echo "⚠️  OVERALL STATUS: ❌ NCCL ENVIRONMENT VARIABLES MISSING"
    echo "   → Apply pretrain.yaml changes and restart training job"
    echo ""
else
    echo ""
    echo "⚠️  OVERALL STATUS: ❌ ISSUES DETECTED - See failures above"
    echo ""
fi

echo "=== RECOMMENDED FIXES ==="
echo "1. If network connectivity fails: Check Kubernetes network policies"
echo "2. If EFA devices missing: Ensure EFA is properly configured on trn2 nodes"
echo "3. If port connection fails: Check security groups allow communication on port 23456"
echo "4. If NCCL env vars missing: Apply pretrain.yaml changes and restart training job"
echo ""
echo "=== IMMEDIATE WORKAROUND ==="
echo "Restart the training job to reset NCCL communication:"
echo "kubectl delete pytorchjob pytorchjob-nxd-llama31-8b -n $NAMESPACE"