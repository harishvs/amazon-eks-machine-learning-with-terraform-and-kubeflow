#!/bin/bash
helm install --debug nxd-llama31-8b    \
        ../../../../charts/machine-learning/model-prep/hf-snapshot    \
        --set-json='env=[{"name":"HF_MODEL_ID","value":"meta-llama/Llama-3.1-8B"},{"name":"HF_TOKEN","value":"hf_xxxxxxxxxxxxxx"},{"name": "HF_TENSORS", "value": "false"}]' \
        -n kubeflow-user-example-com
watch kubectl get pods -n kubeflow-user-example-com
