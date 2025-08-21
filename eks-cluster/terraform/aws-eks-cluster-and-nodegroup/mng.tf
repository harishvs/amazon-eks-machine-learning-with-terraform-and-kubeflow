# Security group for trn2 worker nodes with EFA support
resource "aws_security_group" "trn2_worker_sg" {
  name        = "${var.cluster_name}-trn2-worker-sg"
  description = "Security group for trn2 worker nodes with EFA support"
  vpc_id      = aws_vpc.vpc.id

  # Allow all traffic from the same security group (required for EFA)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "Self-referencing ingress rule for EFA"
  }

  # Allow all ingress traffic from VPC CIDR (required for EKS cluster communication)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_vpc]
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

# Managed Node Group for trn2.48xlarge instances
resource "aws_launch_template" "trn2_48xlarge" {
  name_prefix   = "${var.cluster_name}-trn2-48xlarge-"
  instance_type = "trn2.48xlarge"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_volume_size
      volume_type           = "gp3"
      iops                  = 3000
      encrypted             = true
      delete_on_termination = true
      throughput            = 125
    }
  }

  # EFA network interfaces for trn2.48xlarge (supports up to 32 EFA interfaces)
  dynamic "network_interfaces" {
    for_each = range(0, lookup(var.efa_enabled, "trn2.48xlarge", 0), 1)
    iterator = nic
    content {
      device_index                = nic.value != 0 ? 1 : nic.value
      delete_on_termination       = true
      associate_public_ip_address = false
      interface_type              = "efa"
      network_card_index          = nic.value
      security_groups             = [aws_security_group.trn2_worker_sg.id]
    }
  }

  key_name = var.key_pair != "" ? var.key_pair : null

  # Capacity reservation configuration - only if reservation ID is provided
  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_id != "" ? [1] : []
    content {
      capacity_reservation_target {
        capacity_reservation_id = var.capacity_reservation_id
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-trn2-48xlarge"
    }
  }
}

resource "aws_eks_node_group" "trn2_48xlarge" {
  cluster_name    = aws_eks_cluster.eks_cluster.id
  node_group_name = "trn2-48xlarge"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.private.*.id
  ami_type        = "AL2023_x86_64_NEURON"
  capacity_type   = var.capacity_type

  launch_template {
    id      = aws_launch_template.trn2_48xlarge.id
    version = aws_launch_template.trn2_48xlarge.latest_version
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  # Taints for Neuron workloads
  taint {
    key    = "aws.amazon.com/neuron"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  taint {
    key    = "fsx.csi.aws.com/agent-not-ready"
    effect = "NO_EXECUTE"
  }

  # Apply any custom taints
  dynamic "taint" {
    for_each = var.custom_taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Labels for node identification
  labels = {
    "node.kubernetes.io/instance-type" = "trn2.48xlarge"
    "aws.amazon.com/neuron"            = "true"
    "aws.amazon.com/efa"               = "true"
  }



  depends_on = [
    aws_subnet.private,
    aws_subnet.public,
    aws_route_table_association.private,
    aws_route_table_association.public,
    aws_security_group.trn2_worker_sg,
    helm_release.cluster-autoscaler
  ]
}
