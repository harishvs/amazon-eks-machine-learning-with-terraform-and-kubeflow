        helm install --debug nxd-llama31-8b\
        ../../../../charts/machine-learning/training/pytorchjob-distributed \
        -f pretrain.yaml -n kubeflow-user-example-com