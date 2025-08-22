# Security group for trn2 worker nodes with EFA support
resource "aws_security_group" "trn2_worker_sg" {
  name        = "${var.cluster_name}-trn2-worker-sg"
  description = "Security group for trn2 worker nodes with EFA support"
  vpc_id      = module.vpc.vpc_id

  # Allow all traffic from the same security group (required for EFA)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Self-referencing ingress rule for EFA"
  }

  # Allow all ingress traffic from VPC CIDR (required for EKS cluster communication)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow all traffic from VPC CIDR"
  }

  # Allow outbound traffic to same security group
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Self-referencing egress rule for EFA"
  }

  # Allow all outbound traffic to internet (required for EKS node registration and image pulls)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic to internet"
  }

  tags = {
    Name = "${var.cluster_name}-trn2-worker-sg"
  }
}

# TRN2 node group configuration is now handled in the EKS module in main.tf

# TRN2 node group is now managed through the EKS module in main.tf
# The security group above is kept for potential future EFA configurations
