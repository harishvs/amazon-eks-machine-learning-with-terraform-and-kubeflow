helm install --debug nxd-llama31-70b\
	    charts/machine-learning/training/pytorchjob-distributed \
	        -f examples/training/neuronx-distributed/llama31_70b_trn2/compile.yaml -n kubeflow-user-example-com
