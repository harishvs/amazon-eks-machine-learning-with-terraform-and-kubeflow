# Memory Optimization Suggestions for Llama 3.1 70B Training

## Current Configuration Analysis
- Model: Llama 3.1 70B
- Tensor Parallel (TP): 32
- Pipeline Parallel (PP): 2  
- Global Batch Size: 1024
- Sequence Length: 8192
- Nodes: 2 x trn2.48xlarge (32 Neuron cores each)

## Memory Optimization Strategies

### 1. Reduce Batch Size
```yaml
# In pretrain.yaml, modify:
GBS=512  # Reduce from 1024 to 512
# This will automatically reduce BS and NUM_MICROBATCHES
```

### 2. Reduce Sequence Length
```yaml
SEQ_LEN=4096  # Reduce from 8192 to 4096
```

### 3. Adjust Parallelization Strategy
```yaml
# Option A: Increase Pipeline Parallelism
PP_DEGREE=4  # Increase from 2 to 4
TP_DEGREE=16  # Reduce from 32 to 16

# Option B: Use different TP/PP combination
TP_DEGREE=8
PP_DEGREE=8
```

### 4. Enable Additional Memory Optimizations
Add these environment variables to the training config:

```yaml
env:
  - name: NEURON_RT_STOCHASTIC_ROUNDING_EN
    value: "1"
  - name: NEURON_RT_ASYNC_EXEC_MAX_INFLIGHT_REQUESTS  
    value: "3"  # Reduce from 7 to 3
  - name: MALLOC_ARENA_MAX
    value: "64"  # Reduce from 128 to 64
  - name: NEURON_FUSE_SOFTMAX
    value: "1"
  - name: NEURON_RT_EXEC_TIMEOUT
    value: "120"
```

### 5. Checkpoint and Compilation Optimizations
```yaml
# Reduce checkpoint frequency to save memory
checkpoint_freq=50000  # Increase from 30000

# Use more aggressive selective checkpointing
--use_selective_checkpoint 1
--checkpoint_activations 1  # If available
```

## Immediate Actions to Try

1. **Start with smaller batch size**: Set GBS=256 initially
2. **Reduce sequence length**: Set SEQ_LEN=2048 for testing
3. **Clear compilation cache**: Remove old cached models
4. **Monitor device memory**: Use neuron-monitor during training

## Debugging Commands

```bash
# Check Neuron device status
neuron-ls

# Monitor memory usage
neuron-monitor

# Clear compilation cache
rm -rf /tmp/cache/*
```