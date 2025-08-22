rm -f terraform.tfstate
rm -f terraform.tfstate.backup
rm -rf .terraform/
rm -f .terraform.lock.hcl
aws s3 rm s3://harish-kubeflow-tf/tf2/terraform/state --region ap-southeast-4
