# Project Deployment: ABC Company CI/CD Pipeline

**Author:** Duran Keeley, DevOps Engineer

**Date:** 31 October 2025

**Project:** Automated CI/CD, Deployment, and Monitoring for ABC Company

---

### **1. Introduction**

This document explains the design and build of the CI/CD pipeline for ABC Company. The goal was to create an automated system that allows developers to deliver code quickly while keeping the application reliable, scalable, and easy to maintain.


### **2. Solution Overview**

1. **Cloud:** AWS was chosen for its services, including EKS for container orchestration, EC2 for Jenkins and monitoring servers and ECR for Docker image storage.
2. **Infrastructure as Code:** Terraform provisions all AWS resources in one go, including the VPC, subnets across two Availability Zones, an EKS cluster, and EC2 instances for Jenkins and monitoring.
3. **Configuration as Code:** Ansible takes care of setting up Jenkins and monitoring servers by installing dependencies, configuring services, and applying the right settings.
4. **Source Control:** GitHub hosts the codebase.
5. **Continuous Integration:** Jenkins, configured with JCasC, pulls the latest code and runs the build, test, and packaging steps inside containers defined by go-batect.
6. **Containerisation:** Docker builds the app image, which is versioned and pushed to Amazon ECR for storage.
7. **Continuous Deployment:** Jenkins calls Ansible to deploy the new Docker image to the EKS cluster. Kubernetes manages the rollout and keeps the app running across nodes.
8. **Monitoring:** Prometheus collects metrics from the EKS nodes, and Grafana displays these in dashboards so we can see the system’s health and performance in real time.
9. **Agile:** The use of GitHub projects with a Kanban board view allows to track tasks, bugs, and features.


### **3. Building the Environment with go-batect**

Instead of manually installing Java, Maven, and Git on the build server, I used a tool I made called **go-batect** to define the build environment as code. The `batect.yml` file lists exactly which container images and configurations are used for each step.

This approach runs in a clean environment every build, avoiding "it works on my machine" problems. The Jenkins server only needs Docker and the go-batect binary installed.

```yaml
# batect.yml excerpt
containers:
  maven_builder:
    image: maven:3.8.5-jdk-8
  trivy_scanner:
    image: aquasec/trivy:latest

tasks:
  scan:
    description: "Scan the Java codebase for high and critical vulnerabilities"
    run:
      container: trivy_scanner
  compile:
    description: "Compile, test, and package the application"
    run:
      container: maven_builder
```

### **4. Implementation Stages**

#### **Stage 1: Infrastructure Provisioning**

All AWS resources are defined in Terraform. Running `terraform apply` creates the network, Kubernetes cluster, and EC2 instances. After provisioning Terraform starts a Ansible playbook to configure the servers.

After all resources are up and built there is a ANsible inventory file that lists the Jenkins server and monitoring server for configuration.

Jenkins uses JCasC to skip manual setup. The admin password is created securely and stored in AWS SSM Parameter Store, which Jenkins can access using IAM permissions.

#### **Stage 2: CI/CD Pipeline**

The `Jenkinsfile` defines the end-to-end workflow:

1. **Build and Scan:** Trivy scans for vulnerabilities. Maven compiles and tests the app, and Docker builds the image.
2. **Push to ECR:** Jenkins pushes the image to a private ECR repository.
3. **Deploy to Kubernetes:** Ansible updates the deployment manifest in EKS and applies the new version.

#### **Stage 3: Slack Notifications**

The pipeline can be configured to send build results to Slack. Developers get instant updates on whether a build succeeded or failed, making it easy to act quickly. This can also be configured inside Grafana for monitoring alerts.

#### **Stage 4: Application Deployment**

Once the pipeline completes, the app is live and accessible through the AWS Load Balancer managed by Kubernetes.

#### **Stage 5: Monitoring**

Terraform provisions a monitoring server. Prometheus collects metrics from the EKS cluster, and Grafana provides dashboards to visualise CPU, memory, and uptime data.


### **5. Challenges and Fixes**

One issue I hit was during deployment: the Ansible playbook kept timing out when waiting for Kubernetes pods to become healthy.

Checking Kubernetes events revealed that AWS couldn’t create a Load Balancer because the public subnets were missing the correct tags.

The fix was to add the following tags on the subnets:

* `kubernetes.io/cluster/eks-project-cluster`
* `kubernetes.io/role/elb`

After applying this change, the service created successfully and the pipeline completed as expected.

I also had problems were my EKS was running X86 nodes, but my local Docker builds were ARM-based. This caused image compatibility issues and only was able to find out after multiple failed deployments and using kubectl describe to debug. I switced my EKS node group to ARM-based instances to match my local builds which resolved the issue, but I could have also used docker buildx to create multi-arch images.

THe following commands were used to diagnose issues:

```bash
# Check EKS cluster and resources
kubectl get nodes
kubectl get deployment abc-technologies-deployment
kubectl get pods
kubectl describe pod <pod-name>
kubectl get service abc-technologies-service
kubectl describe service abc-technologies-service
kubectl get deamonset -n monitoring

# Get private IPs of EKS worker nodes
aws ec2 describe-instances --filters "Name=tag:eks:nodegroup-name,Values=app-workers" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text

# Test connectivity to application pod from monitoring server
nc -zv <pod-ip> 9100
```

### **6. Meeting Business Goals**

| Requirement             | How It Was Achieved                                                                                                                                               |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **High Availability**   | The app runs on EKS worker nodes spread across two Availability Zones. Kubernetes handles failover, and the AWS Load Balancer ensures no single point of failure. |
| **Scalability**         | Node groups auto-scale from 1 to 3 nodes based on load. Kubernetes scales pods horizontally as needed.                                                            |
| **Performance**         | Prometheus and Grafana provide real-time performance data so we can catch and fix bottlenecks early.                                                              |
| **Ease of Maintenance** | Everything is version-controlled and defined as code — Terraform for infrastructure, Ansible and JCasC for configuration, go-batect for builds.                      |
| **Speed of Delivery**   | The CI/CD pipeline automates the full process from code commit to deployment, reducing delivery time from days to minutes.                                        |


### **7. Future Improvements**

1. **Resiliency:** Expand EKS to three Availability Zones for even higher availability.
2. **Security:** Add AWS WAF to protect against web vulnerabilities like XSS and SQL injection.
3. **Global Reach:** Use Amazon CloudFront to serve assets closer to users and improve load times.
4. **Cost Optimization:** Implement AWS Savings Plans and Reserved Instances for EC2 and EKS to reduce ongoing costs.
5. **Advanced Monitoring:** Set up alerting in Grafana to notify the team of critical issues via email or Slack.
6. **Blue-Green Deployments:** Implement blue-green deployment strategies in the pipeline to minimize downtime during releases.
7. **Terraform State Management:** Use remote state storage with AWS S3 or Terraform cloud for better collaboration and state locking.
