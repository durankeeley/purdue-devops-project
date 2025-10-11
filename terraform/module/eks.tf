resource "aws_ecr_repository" "app_repo" {
  name = "abc-technologies-ecr-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# NOTE: The custom 'aws_security_group "eks_cluster_sg"' resource has been REMOVED.
# We will add rules directly to the cluster's primary security group managed by EKS.

resource "aws_eks_cluster" "main" {
  name     = "eks-project-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    # NOTE: security_group_ids is REMOVED. EKS will create and manage its own primary SG.
    # We reference this primary SG ID below when adding rules.
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# --- REFINED SECURITY GROUP RULES ---

# 1. Add the ingress rule for Prometheus scraping (port 9100).
#    This rule now targets the primary security group automatically created by the EKS cluster.
resource "aws_security_group_rule" "allow_prometheus_from_monitoring_sg" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  # FIX: Targets the EKS-managed cluster security group ID
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.monitoring_sg.id
  description              = "Allow Prometheus scrapes from Monitoring Server SG"
}

# 2. Add the ingress rule for the Application Load Balancer (port 8080).
#    This rule also targets the EKS-managed cluster security group.
resource "aws_security_group_rule" "allow_app_from_load_balancer" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  # FIX: Targets the EKS-managed cluster security group ID
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow inbound traffic from Load Balancer to App"
}


resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "app-workers"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  instance_types = ["t4g.small"]
  ami_type       = "AL2023_ARM_64_STANDARD"

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name = "eks-app-workers" # Terraform uses 'Name', EKS uses 'eks:nodegroup-name'
  }

  remote_access {
    ec2_ssh_key               = aws_key_pair.deployer_key.key_name
    # Ensure aws_security_group.jenkins_sg is defined elsewhere (e.g., ec2.tf)
    source_security_group_ids = [aws_security_group.jenkins_sg.id]
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    # Ensure rules are associated with the cluster SG before nodes depend on it implicitly.
    aws_security_group_rule.allow_prometheus_from_monitoring_sg,
    aws_security_group_rule.allow_app_from_load_balancer
  ]
}

