helm install --debug nxd-llama31-70b\
    charts/machine-learning/data-prep/data-process \
    -f examples/training/neuronx-distributed/llama31_70b/wikicorpus.yaml -n kubeflow-user-example-com