# ═══════════════════════════════════════════════════════════════════
#   CloudShip — Full Demo Script
#   Run this step-by-step with students to demonstrate the full flow
# ═══════════════════════════════════════════════════════════════════
#
#   STEPS:
#   1. Build & Run Locally          (Docker Desktop only)
#   2. Push to Docker Hub           (needs Docker Hub account)
#   3. Push to AWS ECR              (needs AWS credentials)
#   4. Deploy to AWS ECS Fargate    (needs AWS credentials)
#
#   Usage: Run each section separately, or run the whole script.
#   The script will prompt for all required values.
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "  ⛴️  CloudShip — Full Demo" -ForegroundColor Cyan
Write-Host "  ═══════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

# ─── Configuration ────────────────────────────────────────────────
$IMAGE_NAME = "cloudship"
$IMAGE_TAG  = "v1"

# ═══════════════════════════════════════════════════════════════════
#  STEP 1: BUILD & RUN LOCALLY
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  STEP 1: Build & Run Locally" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

# Build the image
Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
Write-Host "✓ Image built: ${IMAGE_NAME}:${IMAGE_TAG}" -ForegroundColor Green

# Show the image
Write-Host ""
Write-Host "Docker images:" -ForegroundColor Cyan
docker images $IMAGE_NAME

# Run it
Write-Host ""
Write-Host "Starting container on port 8080..." -ForegroundColor Cyan
docker rm -f cloudship-demo 2>$null
docker run -d -p 8080:80 --name cloudship-demo "${IMAGE_NAME}:${IMAGE_TAG}"
Write-Host "✓ Container running!" -ForegroundColor Green
Write-Host ""
Write-Host "  → Open: http://localhost:8080" -ForegroundColor White
Write-Host ""

# Verify
Write-Host "Running containers:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

Read-Host "Press ENTER to continue to Step 2 (Docker Hub)"

# ═══════════════════════════════════════════════════════════════════
#  STEP 2: PUSH TO DOCKER HUB
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  STEP 2: Push to Docker Hub" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

$DOCKER_USER = Read-Host "Enter your Docker Hub username"

# Login
Write-Host ""
Write-Host "Logging in to Docker Hub..." -ForegroundColor Cyan
docker login -u $DOCKER_USER
Write-Host "✓ Logged in to Docker Hub" -ForegroundColor Green

# Tag the image for Docker Hub
$DOCKERHUB_IMAGE = "${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
Write-Host ""
Write-Host "Tagging image: $DOCKERHUB_IMAGE" -ForegroundColor Cyan
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" $DOCKERHUB_IMAGE
Write-Host "✓ Tagged" -ForegroundColor Green

# Push
Write-Host ""
Write-Host "Pushing to Docker Hub..." -ForegroundColor Cyan
docker push $DOCKERHUB_IMAGE
Write-Host "✓ Pushed to Docker Hub!" -ForegroundColor Green
Write-Host ""
Write-Host "  → View: https://hub.docker.com/r/${DOCKER_USER}/${IMAGE_NAME}" -ForegroundColor White
Write-Host ""

Read-Host "Press ENTER to continue to Step 3 (AWS ECR)"

# ═══════════════════════════════════════════════════════════════════
#  STEP 3: PUSH TO AWS ECR
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  STEP 3: Push to AWS ECR" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

# Check/configure AWS
$awsIdentity = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "AWS CLI not configured. Let's set it up:" -ForegroundColor Yellow
    Write-Host "  You need: Access Key ID, Secret Access Key, Region" -ForegroundColor Gray
    Write-Host ""
    aws configure
}

# Get account info
$AWS_ACCOUNT = (aws sts get-caller-identity --query "Account" --output text)
$AWS_REGION  = Read-Host "Enter AWS region (e.g., us-east-1)"
$ECR_REPO    = $IMAGE_NAME

Write-Host ""
Write-Host "AWS Account: $AWS_ACCOUNT" -ForegroundColor Gray
Write-Host "Region:      $AWS_REGION" -ForegroundColor Gray
Write-Host "ECR Repo:    $ECR_REPO" -ForegroundColor Gray
Write-Host ""

# Create ECR repository (ignore error if exists)
Write-Host "Creating ECR repository..." -ForegroundColor Cyan
aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION 2>$null
Write-Host "✓ ECR repository ready: $ECR_REPO" -ForegroundColor Green

# Login Docker to ECR
$ECR_URL = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
Write-Host ""
Write-Host "Logging in Docker to ECR..." -ForegroundColor Cyan
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
Write-Host "✓ Docker logged in to ECR" -ForegroundColor Green

# Tag and push
$ECR_IMAGE = "${ECR_URL}/${ECR_REPO}:${IMAGE_TAG}"
Write-Host ""
Write-Host "Tagging image: $ECR_IMAGE" -ForegroundColor Cyan
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" $ECR_IMAGE
Write-Host "✓ Tagged" -ForegroundColor Green

Write-Host ""
Write-Host "Pushing to ECR..." -ForegroundColor Cyan
docker push $ECR_IMAGE
Write-Host "✓ Pushed to ECR!" -ForegroundColor Green
Write-Host ""
Write-Host "  → View in AWS Console: ECR > Repositories > $ECR_REPO" -ForegroundColor White
Write-Host ""

Read-Host "Press ENTER to continue to Step 4 (ECS Deploy)"

# ═══════════════════════════════════════════════════════════════════
#  STEP 4: DEPLOY TO AWS ECS (FARGATE)
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  STEP 4: Deploy to ECS Fargate" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

$CLUSTER_NAME = "cloudship-cluster"
$SERVICE_NAME = "cloudship-service"
$TASK_FAMILY  = "cloudship-task"

# ─── 4a: Create ECS Cluster ──────────────────────────────────────
Write-Host "Creating ECS cluster: $CLUSTER_NAME..." -ForegroundColor Cyan
aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $AWS_REGION 2>$null | Out-Null
Write-Host "✓ Cluster ready" -ForegroundColor Green

# ─── 4b: Create Task Execution Role (if not exists) ──────────────
Write-Host ""
Write-Host "Setting up IAM role for ECS..." -ForegroundColor Cyan

$trustPolicy = @'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
'@

# Create role (ignore if exists)
$trustPolicy | Out-File -FilePath "$env:TEMP\ecs-trust.json" -Encoding utf8
aws iam create-role `
    --role-name ecsTaskExecutionRole `
    --assume-role-policy-document "file://$env:TEMP\ecs-trust.json" 2>$null | Out-Null

aws iam attach-role-policy `
    --role-name ecsTaskExecutionRole `
    --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" 2>$null

Write-Host "✓ IAM role ready: ecsTaskExecutionRole" -ForegroundColor Green

# ─── 4c: Register Task Definition ────────────────────────────────
Write-Host ""
Write-Host "Registering task definition..." -ForegroundColor Cyan

$taskDef = @"
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT}:role/ecsTaskExecutionRole",
  "containerDefinitions": [{
    "name": "cloudship",
    "image": "$ECR_IMAGE",
    "portMappings": [{
      "containerPort": 80,
      "protocol": "tcp"
    }],
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/$TASK_FAMILY",
        "awslogs-region": "$AWS_REGION",
        "awslogs-stream-prefix": "ecs",
        "awslogs-create-group": "true"
      }
    }
  }]
}
"@

$taskDef | Out-File -FilePath "$env:TEMP\task-def.json" -Encoding utf8
aws ecs register-task-definition --cli-input-json "file://$env:TEMP\task-def.json" --region $AWS_REGION | Out-Null
Write-Host "✓ Task definition registered" -ForegroundColor Green

# ─── 4d: Get default VPC and subnets ─────────────────────────────
Write-Host ""
Write-Host "Getting VPC and subnet info..." -ForegroundColor Cyan

$VPC_ID = (aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
$SUBNETS = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text --region $AWS_REGION) -replace "`t", ","

# Create or get security group
$SG_NAME = "cloudship-sg"
$SG_ID = (aws ec2 describe-security-groups --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[0].GroupId" --output text --region $AWS_REGION 2>$null)

if ($SG_ID -eq "None" -or [string]::IsNullOrEmpty($SG_ID)) {
    $SG_ID = (aws ec2 create-security-group --group-name $SG_NAME --description "CloudShip demo - allow HTTP" --vpc-id $VPC_ID --query "GroupId" --output text --region $AWS_REGION)
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr "0.0.0.0/0" --region $AWS_REGION 2>$null | Out-Null
}

Write-Host "  VPC:     $VPC_ID" -ForegroundColor Gray
Write-Host "  Subnets: $SUBNETS" -ForegroundColor Gray
Write-Host "  SG:      $SG_ID" -ForegroundColor Gray
Write-Host "✓ Networking ready" -ForegroundColor Green

# ─── 4e: Create ECS Service ──────────────────────────────────────
Write-Host ""
Write-Host "Creating ECS service (this deploys the container)..." -ForegroundColor Cyan

# Take first 2 subnets
$subnetList = ($SUBNETS -split ",")[0..1] -join ","

aws ecs create-service `
    --cluster $CLUSTER_NAME `
    --service-name $SERVICE_NAME `
    --task-definition $TASK_FAMILY `
    --desired-count 1 `
    --launch-type FARGATE `
    --network-configuration "awsvpcConfiguration={subnets=[$subnetList],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" `
    --region $AWS_REGION | Out-Null

Write-Host "✓ Service created! Deploying..." -ForegroundColor Green

# ─── 4f: Wait for deployment ─────────────────────────────────────
Write-Host ""
Write-Host "Waiting for task to start (this takes ~60-90 seconds)..." -ForegroundColor Yellow

$maxAttempts = 20
for ($i = 1; $i -le $maxAttempts; $i++) {
    Start-Sleep -Seconds 10
    $taskArns = (aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query "taskArns" --output text --region $AWS_REGION)
    if ($taskArns -and $taskArns -ne "None") {
        $taskArn = ($taskArns -split "`t")[0]
        $taskStatus = (aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $taskArn --query "tasks[0].lastStatus" --output text --region $AWS_REGION)
        Write-Host "  [$i] Task status: $taskStatus" -ForegroundColor Gray

        if ($taskStatus -eq "RUNNING") {
            # Get public IP
            $eni = (aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $taskArn --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text --region $AWS_REGION)
            $PUBLIC_IP = (aws ec2 describe-network-interfaces --network-interface-ids $eni --query "NetworkInterfaces[0].Association.PublicIp" --output text --region $AWS_REGION)
            break
        }
    } else {
        Write-Host "  [$i] Waiting for task to be provisioned..." -ForegroundColor Gray
    }
}

# ─── DONE! ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Local:       http://localhost:8080" -ForegroundColor White
Write-Host "  Docker Hub:  https://hub.docker.com/r/${DOCKER_USER}/${IMAGE_NAME}" -ForegroundColor White
Write-Host "  ECR:         ${ECR_URL}/${ECR_REPO}" -ForegroundColor White
if ($PUBLIC_IP) {
    Write-Host "  ECS (Live):  http://${PUBLIC_IP}" -ForegroundColor Cyan
} else {
    Write-Host "  ECS:         Check AWS Console for public IP" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  ── To clean up later ──" -ForegroundColor DarkGray
Write-Host "  aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 --region $AWS_REGION" -ForegroundColor DarkGray
Write-Host "  aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force --region $AWS_REGION" -ForegroundColor DarkGray
Write-Host "  aws ecs delete-cluster --cluster $CLUSTER_NAME --region $AWS_REGION" -ForegroundColor DarkGray
Write-Host "  aws ecr delete-repository --repository-name $ECR_REPO --force --region $AWS_REGION" -ForegroundColor DarkGray
Write-Host ""
