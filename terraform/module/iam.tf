# This single file defines all IAM Roles, Policies, and EKS Access Entries for the project.
# It is organized by service for clarity and uses depends_on to manage dependencies.

# -----------------------------------------------------------------------------
# SECTION 1: EKS Cluster & Worker Node Roles
# -----------------------------------------------------------------------------

# Role for the EKS Cluster control plane itself.
resource "aws_iam_role" "eks_cluster_role" {
  name = "Project-EKS-ClusterRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Role for the EKS Worker Nodes (the EC2 instances).
resource "aws_iam_role" "eks_node_role" {
  name = "Project-EKS-NodeRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# Grants worker nodes permission to pull images from ECR.
resource "aws_iam_role_policy" "eks_node_ecr_policy" {
  name = "EKS_Node_ECR_Pull_Policy"
  role = aws_iam_role.eks_node_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      Resource = "*"
    }]
  })
}

# -----------------------------------------------------------------------------
# SECTION 2: Jenkins Server Role & Policies
# -----------------------------------------------------------------------------

# Role for the Jenkins EC2 Instance.
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "Project-Jenkins-EC2Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "Project-Jenkins-InstanceProfile"
  role = aws_iam_role.jenkins_ec2_role.name
}

# Attaches managed policies to the Jenkins Role
resource "aws_iam_role_policy_attachment" "jenkins_ecr_power_user" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "jenkins_ssm_managed_instance" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --- FIX IS HERE: Refactored to use a standalone policy and explicit attachment ---
# 1. Define a standalone policy for Jenkins to access EKS.
resource "aws_iam_policy" "jenkins_eks_policy" {
  name        = "Jenkins_EKS_Describe_Policy"
  description = "Allows Jenkins to get EKS cluster details."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["eks:DescribeCluster"],
      Effect   = "Allow",
      Resource = aws_eks_cluster.main.arn
    }]
  })

  depends_on = [aws_eks_cluster.main]
}

# 2. Explicitly attach the policy to the Jenkins role.
resource "aws_iam_role_policy_attachment" "jenkins_eks_policy_attachment" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.jenkins_eks_policy.arn
}

# Inline policy to allow Jenkins to read its admin password from SSM.
resource "aws_iam_role_policy" "jenkins_ssm_policy" {
  name = "Jenkins_SSM_Password_Access"
  role = aws_iam_role.jenkins_ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["ssm:GetParameter"],
      Effect   = "Allow",
      Resource = aws_ssm_parameter.jenkins_admin_password.arn
    }]
  })
  depends_on = [aws_ssm_parameter.jenkins_admin_password]
}

# Creates a Kubernetes access entry for the Jenkins role.
resource "aws_eks_access_entry" "jenkins_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.jenkins_ec2_role.arn
  type          = "STANDARD"
  depends_on    = [aws_eks_cluster.main]
}

# Associates the access entry with Kubernetes admin permissions.
resource "aws_eks_access_policy_association" "jenkins_admin_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.jenkins_ec2_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.jenkins_access]
}

# -----------------------------------------------------------------------------
# SECTION 3: Monitoring Server Role & Policies
# -----------------------------------------------------------------------------

# Role for the Monitoring EC2 Instance.
resource "aws_iam_role" "monitoring_ec2_role" {
  name = "Project-Monitoring-EC2Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "Project-Monitoring-InstanceProfile"
  role = aws_iam_role.monitoring_ec2_role.name
}

# --- Refactored to use a standalone policy and explicit attachment ---
# 1. Define a standalone policy for the monitoring server to access EKS.
resource "aws_iam_policy" "monitoring_eks_policy" {
  name        = "Monitoring_EKS_Describe_Policy"
  description = "Allows the monitoring server to get EKS cluster details."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["eks:DescribeCluster"],
      Effect   = "Allow",
      Resource = aws_eks_cluster.main.arn
    }]
  })
  depends_on = [aws_eks_cluster.main]
}

# 2. Explicitly attach the policy to the monitoring role.
resource "aws_iam_role_policy_attachment" "monitoring_eks_policy_attachment" {
  role       = aws_iam_role.monitoring_ec2_role.name
  policy_arn = aws_iam_policy.monitoring_eks_policy.arn
}

# Inline policy allowing the monitoring server to discover EKS nodes via the EC2 API.
resource "aws_iam_role_policy" "monitoring_ec2_discovery_policy" {
  name   = "Monitoring_EC2_Discovery_Policy"
  role   = aws_iam_role.monitoring_ec2_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = ["ec2:DescribeInstances"],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

# Creates a Kubernetes access entry for the monitoring role.
resource "aws_eks_access_entry" "monitoring_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.monitoring_ec2_role.arn
  type          = "STANDARD"
  depends_on    = [aws_eks_cluster.main]
}

# Associates the access entry with Kubernetes admin permissions.
resource "aws_eks_access_policy_association" "monitoring_admin_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.monitoring_ec2_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.monitoring_access]
}

