cluster_name     = "efa-blog-cluster"
region           = "ap-southeast-4"
azs              = ["ap-southeast-4a", "ap-southeast-4b", "ap-southeast-4c"]
profile          = "default"
import_path      = "s3://harish-kubeflow-tf/ml-platform/"
neuron_az        = "ap-southeast-4c"
system_instances = ["t3.large", "t3.xlarge", "t3.2xlarge", "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge"]

# On-Demand Capacity Reservation ID for trn2.48xlarge instances
capacity_reservation_id = "cr-0adec4eed911dda71" # Replace with your actual capacity reservation ID
