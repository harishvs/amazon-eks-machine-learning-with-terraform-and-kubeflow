output "cluster_vpc" {
  description = "Cluster VPC ID"
  value = module.vpc.vpc_id
}

output "cluster_subnets" {
  description = "Cluster Subnet Ids"
  value = module.vpc.private_subnets
}

output "cluster_id" {
  description = "Cluster Id"
  value = module.eks.cluster_name
}

output "cluster_version" {
  description = "Cluster version"
  value = module.eks.cluster_version
}

output "cluster_endpoint" {
  description = "Cluster Endpoint"
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_arn" {
  description = "Cluster OIDC ARN"
  value = module.eks.oidc_provider_arn
}

output "node_role_arn" {
  description = "Managed node group IAM role ARN"
  value = aws_iam_role.node_role.arn
}

output "efs_id" {
  description = "EFS file-system id"
  value = aws_efs_file_system.fs.id
}

output "efs_dns" {
  description = "EFS file-system DNS"
  value = "${aws_efs_file_system.fs.id}.efs.${var.region}.amazonaws.com"
}

output "fsx_id" {
  description = "FSx for Lustre file-system id"
  value = aws_fsx_lustre_file_system.fs.id
}

output "fsx_mount_name" {
  description = "FSx for Lustre file-system mount name"
  value = aws_fsx_lustre_file_system.fs.mount_name
}

output "static_email" {
  description = "kubeflow email"
  value = var.static_email
}

output "static_username" {
  description = "kubeflow username"
  value = var.static_username
}


output "static_password" {
  description = "kubeflow password"
  sensitive = true
  value = random_password.static_password.result
}

output "mlflow_db_secret_arn" {
  description = "MLFlow DB secret ARN"
  value = module.mlflow.*.db_secret_arn
}

output "slurm_db_password" {
  description = "Slurm DB password"
  sensitive = true
  value = module.slurm.*.db_password
}