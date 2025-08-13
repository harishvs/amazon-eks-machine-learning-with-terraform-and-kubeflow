terraform {
    backend "s3" {
        bucket = "harish-kubeflow-tf"
        key    = "tf2/terraform/state"
        region = "ap-southeast-4"
    }
}
