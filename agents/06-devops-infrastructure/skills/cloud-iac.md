# Skill: Cloud Platforms & Infrastructure as Code

## Objective
Master major cloud platforms (AWS, GCP, Azure) and Infrastructure as Code (IaC) tools to provision, manage, and automate cloud infrastructure at scale.

---

## Part 1: Cloud Computing Fundamentals

### Cloud Service Models

**IaaS (Infrastructure as a Service)**
- Virtual machines, storage, networks
- Examples: AWS EC2, Google Compute Engine, Azure VMs
- You manage: OS, middleware, runtime, applications
- Provider manages: Virtualization, servers, storage, networking

**PaaS (Platform as a Service)**
- Application hosting platforms
- Examples: AWS Elastic Beanstalk, Google App Engine, Azure App Service
- You manage: Applications and data
- Provider manages: Runtime, middleware, OS, infrastructure

**SaaS (Software as a Service)**
- Complete applications
- Examples: Gmail, Salesforce, Office 365
- Provider manages: Everything
- You manage: Configuration and data

### Cloud Deployment Models

- **Public Cloud**: AWS, GCP, Azure (shared infrastructure)
- **Private Cloud**: On-premises, dedicated infrastructure
- **Hybrid Cloud**: Combination of public and private
- **Multi-Cloud**: Multiple public cloud providers

---

## Part 2: Amazon Web Services (AWS)

### Core AWS Services

#### Compute Services

**EC2 (Elastic Compute Cloud)**
```bash
# Launch EC2 instance using AWS CLI
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --key-name my-key-pair \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyInstance}]'

# List instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]'

# Stop instance
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Terminate instance
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

**Lambda (Serverless Functions)**
```python
# lambda_function.py
import json

def lambda_handler(event, context):
    name = event.get('name', 'World')

    return {
        'statusCode': 200,
        'body': json.dumps(f'Hello, {name}!')
    }
```

```bash
# Package and deploy Lambda function
zip function.zip lambda_function.py

aws lambda create-function \
  --function-name hello-world \
  --runtime python3.11 \
  --role arn:aws:iam::123456789012:role/lambda-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://function.zip

# Invoke function
aws lambda invoke \
  --function-name hello-world \
  --payload '{"name":"DevOps"}' \
  response.json
```

**ECS (Elastic Container Service)**
```json
// task-definition.json
{
  "family": "my-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "myrepo/myapp:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENV",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**EKS (Elastic Kubernetes Service)**
```bash
# Create EKS cluster using eksctl
eksctl create cluster \
  --name my-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Update kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Deploy application
kubectl apply -f deployment.yaml
```

#### Storage Services

**S3 (Simple Storage Service)**
```bash
# Create bucket
aws s3 mb s3://my-unique-bucket-name

# Upload file
aws s3 cp file.txt s3://my-unique-bucket-name/

# List objects
aws s3 ls s3://my-unique-bucket-name/

# Sync directory
aws s3 sync ./local-folder s3://my-unique-bucket-name/remote-folder/

# Set bucket policy for public access
aws s3api put-bucket-policy --bucket my-unique-bucket-name --policy file://policy.json

# Enable versioning
aws s3api put-bucket-versioning --bucket my-unique-bucket-name --versioning-configuration Status=Enabled
```

**EBS (Elastic Block Store)**
```bash
# Create volume
aws ec2 create-volume \
  --size 100 \
  --volume-type gp3 \
  --availability-zone us-east-1a

# Attach volume to instance
aws ec2 attach-volume \
  --volume-id vol-1234567890abcdef0 \
  --instance-id i-1234567890abcdef0 \
  --device /dev/sdf
```

#### Database Services

**RDS (Relational Database Service)**
```bash
# Create PostgreSQL database
aws rds create-db-instance \
  --db-instance-identifier mydb \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.3 \
  --master-username admin \
  --master-user-password SecurePassword123 \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-0123456789abcdef0 \
  --backup-retention-period 7 \
  --multi-az

# Create read replica
aws rds create-db-instance-read-replica \
  --db-instance-identifier mydb-replica \
  --source-db-instance-identifier mydb
```

**DynamoDB (NoSQL Database)**
```bash
# Create table
aws dynamodb create-table \
  --table-name Users \
  --attribute-definitions \
    AttributeName=UserId,AttributeType=S \
    AttributeName=Email,AttributeType=S \
  --key-schema \
    AttributeName=UserId,KeyType=HASH \
  --global-secondary-indexes \
    IndexName=EmailIndex,KeySchema=[{AttributeName=Email,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
  --provisioned-throughput \
    ReadCapacityUnits=5,WriteCapacityUnits=5

# Put item
aws dynamodb put-item \
  --table-name Users \
  --item '{"UserId": {"S": "user123"}, "Email": {"S": "user@example.com"}, "Name": {"S": "John Doe"}}'

# Query table
aws dynamodb query \
  --table-name Users \
  --key-condition-expression "UserId = :uid" \
  --expression-attribute-values '{":uid":{"S":"user123"}}'
```

#### Networking Services

**VPC (Virtual Private Cloud)**
```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Create subnet
aws ec2 create-subnet \
  --vpc-id vpc-1234567890abcdef0 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a

# Create internet gateway
aws ec2 create-internet-gateway

# Attach internet gateway to VPC
aws ec2 attach-internet-gateway \
  --vpc-id vpc-1234567890abcdef0 \
  --internet-gateway-id igw-1234567890abcdef0

# Create route table
aws ec2 create-route-table --vpc-id vpc-1234567890abcdef0

# Create route to internet gateway
aws ec2 create-route \
  --route-table-id rtb-1234567890abcdef0 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-1234567890abcdef0
```

**ALB (Application Load Balancer)**
```bash
# Create application load balancer
aws elbv2 create-load-balancer \
  --name my-alb \
  --subnets subnet-12345678 subnet-87654321 \
  --security-groups sg-12345678

# Create target group
aws elbv2 create-target-group \
  --name my-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-1234567890abcdef0 \
  --health-check-path /health

# Register targets
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --targets Id=i-1234567890abcdef0 Id=i-0987654321fedcba0

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...
```

**Route 53 (DNS Service)**
```bash
# Create hosted zone
aws route53 create-hosted-zone \
  --name example.com \
  --caller-reference $(date +%s)

# Create A record
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://change-batch.json
```

```json
// change-batch.json
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.example.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "192.0.2.1"
          }
        ]
      }
    }
  ]
}
```

---

## Part 3: Google Cloud Platform (GCP)

### Core GCP Services

**Compute Engine (Virtual Machines)**
```bash
# Create VM instance
gcloud compute instances create my-instance \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --tags=http-server,https-server

# List instances
gcloud compute instances list

# SSH into instance
gcloud compute ssh my-instance --zone=us-central1-a

# Stop instance
gcloud compute instances stop my-instance --zone=us-central1-a

# Delete instance
gcloud compute instances delete my-instance --zone=us-central1-a
```

**Cloud Functions (Serverless)**
```python
# main.py
def hello_world(request):
    request_json = request.get_json()
    name = request_json.get('name', 'World')
    return f'Hello, {name}!'
```

```bash
# Deploy function
gcloud functions deploy hello-world \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point hello_world

# Invoke function
curl https://REGION-PROJECT_ID.cloudfunctions.net/hello-world \
  -H "Content-Type: application/json" \
  -d '{"name":"GCP"}'
```

**Google Kubernetes Engine (GKE)**
```bash
# Create GKE cluster
gcloud container clusters create my-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 5

# Get credentials
gcloud container clusters get-credentials my-cluster --zone us-central1-a

# Deploy application
kubectl apply -f deployment.yaml

# Delete cluster
gcloud container clusters delete my-cluster --zone us-central1-a
```

**Cloud Storage (Object Storage)**
```bash
# Create bucket
gsutil mb gs://my-unique-bucket-name/

# Upload file
gsutil cp file.txt gs://my-unique-bucket-name/

# List objects
gsutil ls gs://my-unique-bucket-name/

# Make object public
gsutil acl ch -u AllUsers:R gs://my-unique-bucket-name/file.txt

# Sync directory
gsutil -m rsync -r ./local-folder gs://my-unique-bucket-name/remote-folder/

# Enable versioning
gsutil versioning set on gs://my-unique-bucket-name/
```

**Cloud SQL (Managed Databases)**
```bash
# Create PostgreSQL instance
gcloud sql instances create my-postgres \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=SecurePassword123

# Create database
gcloud sql databases create mydb --instance=my-postgres

# Connect to instance
gcloud sql connect my-postgres --user=postgres
```

**Cloud Pub/Sub (Messaging)**
```bash
# Create topic
gcloud pubsub topics create my-topic

# Create subscription
gcloud pubsub subscriptions create my-subscription --topic=my-topic

# Publish message
gcloud pubsub topics publish my-topic --message="Hello, Pub/Sub!"

# Pull messages
gcloud pubsub subscriptions pull my-subscription --auto-ack
```

---

## Part 4: Microsoft Azure

### Core Azure Services

**Virtual Machines**
```bash
# Create resource group
az group create --name MyResourceGroup --location eastus

# Create VM
az vm create \
  --resource-group MyResourceGroup \
  --name MyVM \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys

# Open port
az vm open-port --port 80 --resource-group MyResourceGroup --name MyVM

# List VMs
az vm list --output table

# Stop VM
az vm stop --resource-group MyResourceGroup --name MyVM

# Delete VM
az vm delete --resource-group MyResourceGroup --name MyVM
```

**Azure Functions (Serverless)**
```python
# __init__.py
import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        return func.HttpResponse(f"Hello, {name}!")
    else:
        return func.HttpResponse(
            "Please pass a name",
            status_code=400
        )
```

**Azure Kubernetes Service (AKS)**
```bash
# Create AKS cluster
az aks create \
  --resource-group MyResourceGroup \
  --name MyAKSCluster \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group MyResourceGroup --name MyAKSCluster

# Scale cluster
az aks scale --resource-group MyResourceGroup --name MyAKSCluster --node-count 5
```

**Azure Blob Storage**
```bash
# Create storage account
az storage account create \
  --name mystorageaccount \
  --resource-group MyResourceGroup \
  --location eastus \
  --sku Standard_LRS

# Create container
az storage container create \
  --name mycontainer \
  --account-name mystorageaccount

# Upload blob
az storage blob upload \
  --container-name mycontainer \
  --name myblob \
  --file ./file.txt \
  --account-name mystorageaccount

# List blobs
az storage blob list \
  --container-name mycontainer \
  --account-name mystorageaccount \
  --output table
```

**Azure SQL Database**
```bash
# Create SQL server
az sql server create \
  --name myserver \
  --resource-group MyResourceGroup \
  --location eastus \
  --admin-user sqladmin \
  --admin-password SecurePassword123!

# Create database
az sql db create \
  --resource-group MyResourceGroup \
  --server myserver \
  --name mydb \
  --service-objective S0

# Configure firewall
az sql server firewall-rule create \
  --resource-group MyResourceGroup \
  --server myserver \
  --name AllowAll \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255
```

---

## Part 5: Infrastructure as Code with Terraform

### Terraform Fundamentals

**Basic Terraform Structure**
```hcl
# main.tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

**Variables**
```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

```hcl
# terraform.tfvars
aws_region    = "us-east-1"
environment   = "prod"
instance_type = "t3.small"
vpc_cidr      = "10.0.0.0/16"
```

**Outputs**
```hcl
# outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
```

### Complete AWS Infrastructure Example

**VPC and Networking**
```hcl
# vpc.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.environment}-nat-${count.index + 1}"
  }
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.environment}-private-rt-${count.index + 1}"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

**Security Groups**
```hcl
# security-groups.tf
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}
```

**RDS Database**
```hcl
# rds.tf
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-postgres"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  multi_az               = var.environment == "prod" ? true : false
  skip_final_snapshot    = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.environment}-db-final-snapshot" : null

  tags = {
    Name = "${var.environment}-postgres"
  }
}
```

**ECS Cluster and Service**
```hcl
# ecs.tf
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.environment}-cluster"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_repository_url}:${var.app_version}"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.environment}-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}
```

**Application Load Balancer**
```hcl
# alb.tf
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-app-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  deregistration_delay = 30
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

### Terraform Commands

```bash
# Initialize Terraform
terraform init

# Format code
terraform fmt

# Validate configuration
terraform validate

# Plan changes
terraform plan
terraform plan -out=tfplan

# Apply changes
terraform apply
terraform apply tfplan
terraform apply -auto-approve

# Show current state
terraform show

# List resources
terraform state list

# Destroy infrastructure
terraform destroy
terraform destroy -auto-approve

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0

# Taint resource (force recreation)
terraform taint aws_instance.example

# Workspace management
terraform workspace list
terraform workspace new dev
terraform workspace select prod
```

---

## Part 6: Configuration Management with Ansible

### Ansible Fundamentals

**Inventory File**
```ini
# inventory.ini
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11

[databases]
db1.example.com ansible_host=192.168.1.20

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

```yaml
# inventory.yml
all:
  children:
    webservers:
      hosts:
        web1.example.com:
          ansible_host: 192.168.1.10
        web2.example.com:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db1.example.com:
          ansible_host: 192.168.1.20
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

**Basic Playbook**
```yaml
# playbook.yml
---
- name: Configure web servers
  hosts: webservers
  become: yes

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Copy website files
      copy:
        src: ./website/
        dest: /var/www/html/
        owner: www-data
        group: www-data
        mode: '0644'

    - name: Configure nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/sites-available/default
      notify: Reload nginx

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

**Complete Application Deployment Playbook**
```yaml
# deploy-app.yml
---
- name: Deploy application
  hosts: webservers
  become: yes
  vars:
    app_name: myapp
    app_version: "1.0.0"
    app_user: myapp
    app_dir: "/opt/{{ app_name }}"

  tasks:
    # System setup
    - name: Update system packages
      apt:
        update_cache: yes
        upgrade: dist

    - name: Install required packages
      apt:
        name:
          - python3
          - python3-pip
          - nginx
          - supervisor
          - postgresql-client
        state: present

    # Application user
    - name: Create application user
      user:
        name: "{{ app_user }}"
        shell: /bin/bash
        create_home: yes

    # Application directory
    - name: Create application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'

    # Deploy application
    - name: Copy application files
      synchronize:
        src: ../app/
        dest: "{{ app_dir }}/"
        rsync_opts:
          - "--exclude=.git"
          - "--exclude=*.pyc"
          - "--exclude=__pycache__"

    - name: Set file permissions
      file:
        path: "{{ app_dir }}"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        recurse: yes

    # Install dependencies
    - name: Install Python dependencies
      pip:
        requirements: "{{ app_dir }}/requirements.txt"
        virtualenv: "{{ app_dir }}/venv"
        virtualenv_command: python3 -m venv
      become_user: "{{ app_user }}"

    # Database migration
    - name: Run database migrations
      shell: "{{ app_dir }}/venv/bin/python manage.py migrate"
      args:
        chdir: "{{ app_dir }}"
      become_user: "{{ app_user }}"
      environment:
        DATABASE_URL: "{{ database_url }}"

    # Supervisor configuration
    - name: Configure supervisor
      template:
        src: templates/supervisor.conf.j2
        dest: /etc/supervisor/conf.d/{{ app_name }}.conf
      notify: Restart supervisor

    # Nginx configuration
    - name: Configure nginx
      template:
        src: templates/nginx-app.conf.j2
        dest: /etc/nginx/sites-available/{{ app_name }}
      notify: Reload nginx

    - name: Enable nginx site
      file:
        src: /etc/nginx/sites-available/{{ app_name }}
        dest: /etc/nginx/sites-enabled/{{ app_name }}
        state: link
      notify: Reload nginx

    # Firewall
    - name: Configure UFW
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - '22'
        - '80'
        - '443'

    - name: Enable UFW
      ufw:
        state: enabled

  handlers:
    - name: Restart supervisor
      service:
        name: supervisor
        state: restarted

    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

### Ansible Roles

**Role Structure**
```
roles/
└── webserver/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    │   └── nginx.conf.j2
    ├── files/
    ├── vars/
    │   └── main.yml
    ├── defaults/
    │   └── main.yml
    └── meta/
        └── main.yml
```

**Using Roles**
```yaml
# site.yml
---
- name: Configure infrastructure
  hosts: all
  become: yes

  roles:
    - common
    - security
    - webserver
    - database
    - monitoring
```

### Ansible Commands

```bash
# Ping all hosts
ansible all -i inventory.ini -m ping

# Run ad-hoc command
ansible webservers -i inventory.ini -a "uptime"

# Run playbook
ansible-playbook -i inventory.ini playbook.yml

# Check syntax
ansible-playbook --syntax-check playbook.yml

# Dry run
ansible-playbook -i inventory.ini playbook.yml --check

# Run with verbose output
ansible-playbook -i inventory.ini playbook.yml -vvv

# Limit to specific hosts
ansible-playbook -i inventory.ini playbook.yml --limit web1.example.com

# Use tags
ansible-playbook -i inventory.ini playbook.yml --tags "deploy"
ansible-playbook -i inventory.ini playbook.yml --skip-tags "database"
```

---

## Part 7: Multi-Cloud Strategies

### Multi-Cloud Architecture Patterns

**1. Cloud-Agnostic Infrastructure**
- Use containerization (Docker, Kubernetes)
- Deploy same containers across clouds
- Abstract cloud-specific services

**2. Best-of-Breed Approach**
- Use each cloud's strengths
- AWS for compute, GCP for ML, Azure for enterprise

**3. Active-Active Multi-Cloud**
- Deploy applications across multiple clouds simultaneously
- Load balance between clouds
- Disaster recovery and high availability

**4. Migration/Hybrid Strategy**
- Gradual migration from one cloud to another
- Keep legacy systems in one cloud
- New workloads in different cloud

### Multi-Cloud with Terraform

```hcl
# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
}

provider "azurerm" {
  features {}
}
```

```hcl
# multi-cloud-app.tf
# Deploy to AWS
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  tags = {
    Name = "aws-app"
  }
}

# Deploy to GCP
resource "google_compute_instance" "app" {
  name         = "gcp-app"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

# Deploy to Azure
resource "azurerm_linux_virtual_machine" "app" {
  name                = "azure-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
```

---

## Best Practices

### Infrastructure as Code
1. Version control all IaC code
2. Use modules for reusability
3. Implement state management
4. Use remote backends
5. Separate environments
6. Document code thoroughly
7. Implement code review process
8. Use consistent naming conventions

### Cloud Security
1. Use IAM roles and policies
2. Enable encryption at rest and in transit
3. Implement network segmentation
4. Use security groups/firewalls
5. Enable audit logging
6. Regular security scanning
7. Rotate credentials regularly
8. Follow principle of least privilege

### Cost Optimization
1. Right-size instances
2. Use auto-scaling
3. Leverage spot/preemptible instances
4. Use reserved instances for stable workloads
5. Implement cost monitoring and alerts
6. Delete unused resources
7. Use lifecycle policies for storage
8. Optimize data transfer

## Success Indicators

- [ ] Provisioned infrastructure across multiple clouds
- [ ] Automated infrastructure deployment with Terraform
- [ ] Configured resources using Ansible
- [ ] Implemented infrastructure versioning
- [ ] Optimized cloud costs
- [ ] Secured cloud resources
- [ ] Documented infrastructure architecture
- [ ] Implemented disaster recovery
- [ ] Set up monitoring and alerting
- [ ] Achieved infrastructure reproducibility
