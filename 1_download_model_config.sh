#!/bin/bash

set -o allexport

source ./.env

set +o allexport


echo "*************hf token is $HF_TOKEN"
helm install --debug nxd-llama31-70b    \
    charts/machine-learning/model-prep/hf-snapshot    \
    --set-json='env=[{"name":"HF_MODEL_ID","value":"meta-llama/Llama-3.1-70B"},{"name":"HF_TOKEN","value":"hf_xxxxxxxxxxxx"},{"name": "HF_TENSORS", "value": "false"}]' \
    -n kubeflow-user-example-com

# helm install --debug nxd-llama31-70b    \
#     charts/machine-learning/model-prep/hf-snapshot    \
#     --set-json='env=[{"name":"HF_MODEL_ID","value":"meta-llama/Llama-3.1-70B"},{"name":"HF_TOKEN","value":"YourHuggingFaceToken"},{"name": "HF_TENSORS", "value": "false"}]' \
#     -n kubeflow-user-example-com