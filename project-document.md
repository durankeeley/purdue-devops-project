# Project 1

# Building a CI/CD Pipeline for a Retail Company

## Table of Content

- 1. Business Challenge/Requirement
- 2. The Goal of the Project
- 3. Data Flow Architecture/Process Flow
- 4. Data Explanation and Schema:
- 5. Problem Statements/Tasks
- 6. Pre-requisites:
- 7. Approach to Solve:
- 8. Considerations/Assumptions
- 9. Deliverables
- 10. Business Benefits
- 11. How to submit the project
- 12. Marks Allocation

## 1. Business Challenge/Requirement

ABC technologies is a leading online retail store. ABC has recently acquired a large retails offline business store. The business store has large number of stores across the globe but is following conventional pattern of development and deployment. As a result, it has landed to great loss and are facing below challenges.

- low available
- low scalable
- low Performance
- Hard built and maintained
- Developed and deployed is time consuming

ABC will acquire the data from all these storage systems and plan to use it for analytics and prediction of the firm’s growth and sales prospect. In the first phase ABC has to create the servlets to Add a product and Display product details. Add servlet dependencies required to compile the servlets. Create an HTML page which will be used to add a product. Team is using git to keep all the source code.

ABC has decided to use DevOps model and Once source code is available in Github, we need to integrate it with Jenkins and provide continuous build generation for continuous Delivery, integrate with Ansible and Kubernetes for deployment. Use docker hub to pull and push images between ansible and Kubernetes.

## 2. The Goal of the Project

Below are some of the high-level goals of this project:

- Implement CICD such that ABC Company to is able to be
    1. Highly available
    2. Highly scalable
    3. Highly Performant
    4. Easily built and maintained
    5. Developed and deployed quickly


## 3. Data Flow Architecture/Process Flow

1. GitHub - Source Code Management
2. Jenkins - Compile code, test code, deploy tomcat docker container
3. Docker/Ansible - Deploy to Kubernetes
4. Grafana - Monitor resources

## 4. Data Explanation and Schema:

Sample Java project has been shared for usage. It is a maven project and has src and test folders created into it. It has a POM.xml file which lists all needed dependencies to execute this project.

## 5. Problem Statements/Tasks

We need to develop a CICD pipeline to automate the software development, testing, package, deploy reducing the time to market of app and ensuring good quality service is experienced by end users. In this project we need to

1. Push the code to out github repository
2. Create a continuous integration pipeline using Jenkins to compile,test and package the code present in Github
3. Write dockerfile to push the war file to tomcat server
4. Integrate docker with Ansible and write playbook
5. Deploy artifacts to Kubernetes cluster
6. Monitor resources using grafana


## 6. Pre-requisites:


Verify following software is installed in the working machine

1. Java
2. Maven
3. Git
4. Jenkins
5. Docker
6. Ansible
7. Kubernetes
8. Grafana
9. Prometheus

## 7. Approach to Solve:

**Task 1:** Clone the project from github link shared in resources to your local machine. Build the code using maven commands.

**Task 2:** Setup git repository and push the source code. Login to Jenkins

1. create a build pipeline containing a job each
    - One for compiling source code
    - Second for testing source code
    - Third for packing the code
2. Execute CICD pipeline to execute the jobs created in step
3. Setup master-slave node to distribute the tasks in pipeline

**Task 3** : Write a Dockerfile Create an Image and container on docker host. Integrate docker host with Jenkins. Create CI/CD job on Jenkins to build and deploy on a container

1. Enhance the packagejob created in step 1 of task 2 to create a docker image
2. In the docker image add code to move the war file to tomcat server and build the image

**Task 4:** Integrate Docker host with Ansible. Write ansible playbook to create Image and create continuer. Integrate Ansible with Jenkins. Deploy ansible-playbook. CI/CD job to build code on ansible and deploy it on docker container

1. Deploy Artifacts on Kubernetes
2. Write pod, service, and deployment manifest file
3. Integrate Kubernetes with ansible
4. Ansible playbook to create deployment and service


**Task 5:** Using Prometheus monitor the resources like CPU utilization: Total Usage, Usage per core, usage breakdown, Memory , Network on the instance by providing the end points in local host. Install node exporter and add URL to target in Prometheus. Using this data login to Grafana and create a dashboard to show the metrics.

## 8. Considerations/Assumptions

## Resources Needed:

- An AWS account
- A github account
- MobaXterm / Putty
- Git Bash setup
- Source Code

## 9. Deliverables

- Create a detailed solution document with screenshot for each task.
- Please submit complete code developed by you including docker file, playbook etc.
- Please submit all the screenshots.

## 10. Business Benefits


After the solution is built, the business will have the below operational benefits:

1. Highly available
2. Highly scalable
3. Highly Performant
4. Easily built and maintained
5. Developed and deployed quickly
6. Lower production bugs
7. Frequent releases
8. Better customer experiences
9. Lesser time to market

## 11 How to submit the project
  
- A detailed solution document explaining each step with screenshots (Google Docs link)
- All code/scripts developed during the project.
- GitHub repository link.
- Ticket Subject: IGP Project Submission

## 12 Marks Allocation

- Creation of CI pipeline in Jenkins [20 Marks]
- Creation of Docker file and integration with Ansible [30 Marks]
- Deploy artifacts to Kubernetes [35 Marks]
- Creation of Prometheus to monitor node [15 Marks]

