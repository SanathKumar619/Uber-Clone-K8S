# Uber Clone DevSecOps CI/CD Kubernetes Project

![](https://miro.medium.com/v2/resize:fit:736/0*xJc4sgDsMZqdfPyZ.png)

# **Introduction :-**

In the fast-paced world of app development, the need for a seamless and secure Continuous Integration/Continuous Deployment (CI/CD) pipeline cannot be overstated. For businesses looking to replicate the success of Uber, it’s crucial to implement a DevSecOps approach that ensures both speed and security throughout the software development lifecycle. In this blog post, we’ll explore the key components of a DevSecOps CI/CD pipeline for an Uber clone, emphasizing the importance of integrating security into every stage of the development process.

**Github Repo** :- 

## **STEP 1: Launch an Ubuntu instance (T2.large) :-**

Launch an AWS T2 Large Instance. Use the image as Ubuntu. You can create a new key pair or use an existing one. Enable HTTP and HTTPS settings in the Security Group and open all ports .

## **STEP 2: Create IAM role :-**

Search for IAM in the search bar of AWS and click on roles

Now Attach this role to Ec2 instance that we created earlier, so we can provision cluster from that instance.

Go to EC2 Dashboard and select the instance.

Click on Actions → Security → Modify IAM role.

Select the Role that created earlier and click on Update IAM role.

Connect the instance to GitBash or Putty

## **STEP 3: Installations of Packages :-**

create shell script in Ubuntu ec2 instance

```bash
sudo su   #run from inside root
vi script1.sh
```

Enter this script into it  
This script installs Jenkins, Docker , Kubectl, Terraform, AWS Cli,Sonarqube

```bash
#!/bin/bash
sudo apt update -y
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y
sudo apt install temurin-17-jdk -y
/usr/bin/java --version
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins
#install docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker ubuntu
newgrp docker
```

Now provide executable permissions to shell script

```bash
chmod 777 script1.sh
sh script1.sh
```

Let’s Run the second script

```bash
vi script2.sh
```

Add this script

```bash
#!/bin/bash
# install trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
#install terraform
sudo apt install wget -y
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
#install Kubectl on Jenkins
sudo apt update
sudo apt install curl -y
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
#install Aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install unzip -y
unzip awscliv2.zip
sudo ./aws/install
```

Now provide executable permissions to shell script

```bash
chmod 777 script2.sh
sh script2.sh
```

Now check the versions of packages

```bash
docker --version
trivy --version
aws --version
terraform --version
kubectl version
```

Run Sonarqube in Docker

```bash
sudo chmod 777 /var/run/docker.sock
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
```

## **STEP 4: Connect to Jenkins and Sonarqube :-**

Now copy the public IP address of ec2 and paste it into the browser

```bash
<Ec2-ip:8080> #you will Jenkins login page
```
Connect your Instance to Putty or GitBash and provide the below command for the Administrator password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Now you see Jenkins Dashboard

Now Copy the public IP again and paste it into a new tab in the browser with 9000

```bash
<ec2-ip:9000>  #runs sonar container
```

Enter username and password, click on login and change password

```bash
username admin
password admin
```

Update New password, This is Sonar Dashboard.

## **STEP 5: Terraform plugin install and EKS provision :-**

Now go to Jenkins and add a terraform plugin to provision the AWS EKS using the Pipeline Job.

Go to Jenkins dashboard –&gt; Manage Jenkins –&gt; Plugins

Available Plugins, Search for Terraform and install it.

Go to Mobaxtream and use the below command

let’s find the path to our Terraform (we will use it in the tools section of Terraform)

```bash
which terraform
```

Now come back to Manage Jenkins –&gt; Tools

Add the terraform in Tools in jenkins - manage jenkins

Apply and save.

CHANGE YOUR S3 BUCKET NAME IN THE EKS/backend.tf

Now create a new job for the EKS provision

I want to do this with build parameters to apply and destroy while building only.

To do that go to configre -> This project is parameterized -> in name-> action , in choices -> apply destroy
Let’s add a pipeline

```bash
pipeline{
    agent any
    stages {
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/SanathKumar619/Uber-Clone-K8S.git'
            }
        }
        stage('Terraform version'){
             steps{
                 sh 'terraform --version'
             }
        }
        stage('Terraform init'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform init'
                   }
             }
        }
        stage('Terraform validate'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform validate'
                   }
             }
        }
        stage('Terraform plan'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform plan'
                   }
             }
        }
        stage('Terraform apply/destroy'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform ${action} --auto-approve'
                   }
             }
        }
    }
}
```

Let’s apply and save and Build with parameters and select action as apply

Stage will take max 10mins to provision
Check in Your Aws console whether it created EKS or not.
Ec2 instance is created for the Node group

## **STEP 6: Plugins installation & setup (Java, Sonar, Nodejs, owasp, Docker)**

Go to Jenkins dashboard

Manage Jenkins –&gt; Plugins –&gt; Available Plugins

Search for the Below Plugins

`Eclipse Temurin installer`

`Sonarqube Scanner`

`NodeJs`

`Owasp Dependency-Check`

`Docker`

`Docker Commons`

`Docker Pipeline`

`Docker API`

`Docker-build-step`

## **STEP 7: Configure in Global Tool Configuration :-**

Goto Manage Jenkins → Tools → Install JDK(17) and NodeJs(16)→ Click on Apply and Save

For Sonarqube use the latest version

For Owasp use the 6.5.1 version

Use the latest version of Docker

Click apply and save.

## **STEP 8: Configure Sonar Server in Manage Jenkins :-**

Grab the Public IP Address of your EC2 Instance, Sonarqube works on Port 9000, so &lt;Public IP&gt;:9000. Goto your Sonarqube Server. Click on Administration → Security → Users → Click on Tokens and Update Token → Give it a name → and click on Generate Token

click on update Token

Create a token with a name and generate

copy Token , Goto Jenkins Dashboard → Manage Jenkins → Credentials → Add Secret Text. It should look like this

You will this page once you click on create

Now, go to Dashboard → Manage Jenkins → System and Add like the below image.

Click on Apply and Save

The Configure System option is used in Jenkins to configure different server

Global Tool Configuration is used to configure different tools that we install using Plugins

We will install a sonar scanner in the tools.

In the Sonarqube Dashboard add a quality gate also

Administration → Configuration →Webhooks

Add details

```bash
#in url section of quality gate
<http://jenkins-public-ip:8080>/sonarqube-webhook/
```

Now add Docker credentials to the Jenkins to log in and push the image

Manage Jenkins –&gt; Credentials –&gt; global –&gt; add credential

Add DockerHub Username and Password under Global Credentials and create.

## **STEP 09: RUN an Pipeline :-**

Add this code to Pipeline

```groovy
pipeline{
    agent any
    tools{
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/SanathKumar619/Uber-Clone-K8S.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('Sonar-Server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Uber \
                    -Dsonar.projectKey=Uber'''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-Token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'Dp-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
         stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh "docker build -t uber ."
                       sh "docker tag uber sushantkapare1717/uber:latest "
                       sh "docker push sushantkapare1717/uber:latest "
                    }
                }
            }
        }
        stage("TRIVY"){
            steps{
                sh "trivy image sushantkapare1717/uber:latest > trivyimage.txt"
            }
        }
        stage("deploy_docker"){
            steps{
                sh "docker run -d --name uber -p 3000:3000 sushantkapare1717/uber:latest"
            }
        }
    }
}
```

Click on Apply and save. amd Build now,

To see the report, you can go to Sonarqube Server and go to Projects.

You can see the report has been generated and the status shows as passed. You can see that there are 1.2k lines it scanned. To see a detailed report, you can go to issues.

OWASP, You will see that in status, a graph will also be generated and Vulnerabilities.

When you log in to Dockerhub, you will see a new image is created

## **STEP 10: Kubernetes Deployment**

Go to Putty of your Jenkins instance SSH and enter the below command

```bash
aws eks update-kubeconfig --name <CLUSTER NAME> --region <CLUSTER REGION>
aws eks update-kubeconfig --name EKS_CLOUD --region eu-west-1
```
To see nodes: 
```bash
kubectl get nodes
```

Copy the config file to Jenkins master or the local file manager and save it : ~/.kube/config

copy it and save it in documents or another folder save it as secret-file.txt

Note: create a secret-file.txt in your file explorer save the config in it and use this at the kubernetes credential section.

Install Kubernetes Plugin, Once it’s installed successfully

goto manage Jenkins –&gt; manage credentials –&gt; Click on Jenkins global –&gt; add credentials

final step to deploy on the Kubernetes cluster

```groovy
stage('Deploy to kubernetes'){
            steps{
                script{
                    dir('K8S') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                                sh 'kubectl apply -f deployment.yml'
                                sh 'kubectl apply -f service.yml'
                        }
                    }
                }
            }
        }
```
If we pass our IP and port number we can see output.

## **STEP 11: Termination Process :-**

Now Go to Jenkins Dashboard and click on Terraform-Eks job

And build with parameters and destroy action

It will delete the EKS cluster that provisioned

After 10 minutes cluster will delete and wait for it. Don’t remove ec2 instance till that time.

**Cluster deleted**

**Delete the Ec2 instance.**

### Thats a Wrap!❤️
