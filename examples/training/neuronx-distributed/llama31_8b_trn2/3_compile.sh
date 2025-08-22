source uninstall_helm.sh
helm install --debug nxd-llama31-8b\
        ../../../../charts/machine-learning/training/pytorchjob-distributed \
        -f compile.yaml -n kubeflow-user-example-com
watch kubectl get pods -n kubeflow-user-example-com
