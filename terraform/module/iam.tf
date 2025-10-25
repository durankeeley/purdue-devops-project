# EKS Cluster & Worker Node Roles

## Role for the EKS Cluster control plane itself
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

## Role for the EKS EC2 Worker Nodes
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

## Grants worker nodes permission to pull images from ECR
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

# Jenkins Server Role & Policies

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

resource "aws_iam_role_policy_attachment" "jenkins_ecr_power_user" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "jenkins_ssm_managed_instance" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

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

resource "aws_iam_role_policy_attachment" "jenkins_eks_policy_attachment" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.jenkins_eks_policy.arn
}

resource "aws_iam_policy" "jenkins_ssm_policy" {
  name        = "Jenkins_SSM_Password_Access_Policy"
  description = "Allows Jenkins to read its admin password from SSM Parameter Store."
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

resource "aws_iam_role_policy_attachment" "jenkins_ssm_policy_attachment" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.jenkins_ssm_policy.arn
}

resource "aws_eks_access_entry" "jenkins_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.jenkins_ec2_role.arn
  type          = "STANDARD"
  depends_on    = [aws_eks_cluster.main]
}

resource "aws_eks_access_policy_association" "jenkins_admin_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.jenkins_ec2_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.jenkins_access]
}


# Monitoring Server Role & Policies

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

resource "aws_iam_role_policy_attachment" "monitoring_eks_policy_attachment" {
  role       = aws_iam_role.monitoring_ec2_role.name
  policy_arn = aws_iam_policy.monitoring_eks_policy.arn
}

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

resource "aws_eks_access_entry" "monitoring_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.monitoring_ec2_role.arn
  type          = "STANDARD"
  depends_on    = [aws_eks_cluster.main]
}

resource "aws_eks_access_policy_association" "monitoring_admin_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.monitoring_ec2_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  depends_on = [aws_eks_access_entry.monitoring_access]
}
