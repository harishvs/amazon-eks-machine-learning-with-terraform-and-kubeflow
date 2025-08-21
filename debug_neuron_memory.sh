#!/bin/bash

echo "=== Neuron Device Status ==="
neuron-ls

echo -e "\n=== Neuron Memory Usage ==="
neuron-monitor --help 2>/dev/null || echo "neuron-monitor not available"

echo -e "\n=== System Memory ==="
free -h

echo -e "\n=== Disk Space ==="
df -h /tmp

echo -e "\n=== Process Memory Usage ==="
ps aux --sort=-%mem | head -10

echo -e "\n=== Neuron Runtime Processes ==="
ps aux | grep -E "(neuron|nrt)" | grep -v grep

echo -e "\n=== Check for Core Dumps ==="
ls -la /tmp/core* 2>/dev/null || echo "No core dumps found"

echo -e "\n=== Neuron Cache Size ==="
du -sh /tmp/cache 2>/dev/null || echo "No cache directory found"

echo -e "\n=== Clear Neuron Cache ==="
echo "To clear cache, run: rm -rf /tmp/cache/*"

echo -e "\n=== Environment Variables ==="
env | grep -E "(NEURON|XLA|MALLOC)" | sort