    source uninstall_helm.sh
    helm install --debug nxd-llama31-8b\
        ../../../../charts/machine-learning/data-prep/data-process \
        -f wikicorpus.yaml -n kubeflow-user-example-com
    watch kubectl get pods -n kubeflow-user-example-com
