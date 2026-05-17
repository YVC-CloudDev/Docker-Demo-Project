<p align="center">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/nginx-009639?style=for-the-badge&logo=nginx&logoColor=white" />
  <img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white" />
  <img src="https://img.shields.io/badge/AWS_ECR-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" />
  <img src="https://img.shields.io/badge/AWS_ECS-FF9900?style=for-the-badge&logo=amazon-ecs&logoColor=white" />
</p>

# ⛴️ CloudShip — Docker Demo Project

A modern containerized web application with **4 CI/CD pipeline options** — from simple Docker Hub push to full AWS ECS deployment.

> **Course:** Cloud-Based Application Development — YVC 2026  
> **Lecturer:** Rotem Levi

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [CI/CD Options](#-cicd-options)
- [Option 1: Docker Hub](#option-1-docker-hub)
- [Option 2: GitHub Container Registry](#option-2-github-container-registry-ghcr)
- [Option 3: AWS ECR](#option-3-aws-ecr)
- [Option 4: AWS ECR + ECS](#option-4-aws-ecr--ecs-full-pipeline)
- [Docker Commands Cheat Sheet](#-docker-commands-cheat-sheet)
- [How to Fork & Use](#-how-to-fork--use)
- [Architecture](#-architecture)
- [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

```bash
# Clone this repo
git clone https://github.com/YVC-CloudDev/Docker-Demo-Project.git
cd Docker-Demo-Project

# Build the Docker image
docker build -t cloudship .

# Run locally
docker run -d -p 8080:80 --name cloudship cloudship

# Open in browser
# → http://localhost:8080

# Stop & cleanup
docker stop cloudship && docker rm cloudship
```

---

## 📁 Project Structure

```
├── index.html              # Website — HTML structure
├── style.css               # Website — Styling & animations
├── app.js                  # Website — Interactive features (particles, terminal)
├── Dockerfile              # 🐳 Docker build instructions
├── .dockerignore           # Files excluded from Docker image
├── .gitignore              # Files excluded from Git
├── task-definition.json    # AWS ECS Fargate task configuration
├── demo.ps1                # PowerShell script for live demo in class
└── .github/
    └── workflows/
        ├── docker-hub.yml  # Option 1: Push to Docker Hub
        ├── ghcr.yml        # Option 2: Push to GitHub Container Registry
        ├── ecr.yml         # Option 3: Push to AWS ECR
        └── ecr-ecs.yml     # Option 4: Push to ECR + Deploy to ECS
```

---

## 🔄 CI/CD Options

Choose the option that matches your learning stage:

| # | Option | Registry | Deploy | Difficulty | Setup |
|---|--------|----------|--------|:----------:|-------|
| 1 | **Docker Hub** | Docker Hub | Manual pull | ⭐ | 2 secrets |
| 2 | **GHCR** | GitHub Packages | Manual pull | ⭐ | **None!** |
| 3 | **AWS ECR** | AWS ECR | Manual | ⭐⭐ | 2 secrets + 2 vars |
| 4 | **ECR + ECS** | AWS ECR | Auto → ECS | ⭐⭐⭐ | 2 secrets + 5 vars |

> **💡 Tip:** Start with Option 2 (GHCR) — it requires zero setup!

---

## Option 1: Docker Hub

**Best for:** Public images, sharing with others, simplest registry concept.

### Setup Steps

1. Create account at [hub.docker.com](https://hub.docker.com)
2. Create access token: **Account Settings → Security → New Access Token**
3. In your GitHub repo: **Settings → Secrets and variables → Actions**
4. Add **Secrets:**

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | The access token |

### Enable the Workflow

Rename or copy `.github/workflows/docker-hub.yml` to trigger on push, or run manually from the **Actions** tab.

### Flow

```
git push → GitHub Actions → docker build → docker push → Docker Hub
                                                              ↓
                                          docker pull username/cloudship:latest
```

---

## Option 2: GitHub Container Registry (GHCR)

**Best for:** Getting started fast — **NO SETUP REQUIRED!** Uses your GitHub token automatically.

### Setup Steps

✅ **None!** The workflow uses `GITHUB_TOKEN` which is provided automatically.

Just enable the workflow and push.

### Enable the Workflow

The workflow file `.github/workflows/ghcr.yml` is ready to go.

### Flow

```
git push → GitHub Actions → docker build → docker push → ghcr.io
                                                              ↓
                                          docker pull ghcr.io/YVC-CloudDev/docker-demo-project:latest
```

### Pull the Image

```bash
# Login to GHCR (use a GitHub personal access token)
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Pull and run
docker pull ghcr.io/YVC-CloudDev/docker-demo-project:latest
docker run -d -p 8080:80 ghcr.io/YVC-CloudDev/docker-demo-project:latest
```

---

## Option 3: AWS ECR

**Best for:** Private images, AWS integration, production workloads.

### Setup Steps

1. **Create ECR repository:**
   ```bash
   aws ecr create-repository --repository-name cloudship --region us-east-1
   ```

2. **Create IAM user** with these permissions:
   - `AmazonEC2ContainerRegistryPowerUser`

3. **Add GitHub Secrets:**

   | Secret Name | Value |
   |-------------|-------|
   | `AWS_ACCESS_KEY_ID` | IAM user access key |
   | `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

4. **Add GitHub Variables** (Settings → Variables → Actions → New variable):

   | Variable Name | Value |
   |---------------|-------|
   | `AWS_REGION` | `us-east-1` (or your region) |
   | `ECR_REPOSITORY` | `cloudship` |

### Flow

```
git push → GitHub Actions → docker build → docker push → AWS ECR (private)
```

---

## Option 4: AWS ECR + ECS (Full Pipeline)

**Best for:** Full production deployment — push code, app goes live automatically!

### Setup Steps

1. Complete **Option 3** setup first

2. **Create ECS Cluster:**
   ```bash
   aws ecs create-cluster --cluster-name cloudship-cluster --region us-east-1
   ```

3. **Register Task Definition:**
   ```bash
   aws ecs register-task-definition --cli-input-json file://task-definition.json --region us-east-1
   ```
   > ⚠️ Edit `task-definition.json` first — replace `ACCOUNT_ID` and `REGION`

4. **Create ECS Service:**
   ```bash
   aws ecs create-service \
     --cluster cloudship-cluster \
     --service-name cloudship-service \
     --task-definition cloudship \
     --desired-count 1 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[YOUR_SUBNET],securityGroups=[YOUR_SG],assignPublicIp=ENABLED}"
   ```

5. **Add additional GitHub Variables:**

   | Variable Name | Value |
   |---------------|-------|
   | `ECS_CLUSTER` | `cloudship-cluster` |
   | `ECS_SERVICE` | `cloudship-service` |
   | `CONTAINER_NAME` | `cloudship` |

### Flow

```
git push → GitHub Actions → docker build → push to ECR → update ECS → 🚀 LIVE!
```

---

## 📝 Docker Commands Cheat Sheet

### Build & Run

```bash
docker build -t cloudship .            # Build image
docker run -d -p 8080:80 cloudship     # Run container (background)
docker run -it cloudship sh            # Run + open shell inside
```

### Manage Containers

```bash
docker ps                              # List running containers
docker ps -a                           # List ALL containers
docker stop <name>                     # Stop a container
docker rm <name>                       # Remove a container
docker logs <name>                     # View container logs
docker logs -f <name>                  # Follow logs (live)
```

### Manage Images

```bash
docker images                          # List all images
docker rmi <image>                     # Delete an image
docker pull nginx:alpine               # Download an image
docker tag myimg user/myimg:v1         # Tag for registry
docker push user/myimg:v1              # Push to registry
```

### Registry Commands

```bash
# Docker Hub
docker login
docker push username/cloudship:v1

# AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com
docker push ACCOUNT.dkr.ecr.REGION.amazonaws.com/cloudship:v1

# GitHub Container Registry
echo $TOKEN | docker login ghcr.io -u USERNAME --password-stdin
docker push ghcr.io/USERNAME/cloudship:v1
```

### Cleanup

```bash
docker system prune                    # Remove unused data
docker container prune                 # Remove stopped containers
docker image prune -a                  # Remove unused images
```

---

## 🍴 How to Fork & Use

### For Students:

1. **Fork** this repository (top-right button)
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Docker-Demo-Project.git
   cd Docker-Demo-Project
   ```
3. **Build & run** locally:
   ```bash
   docker build -t cloudship .
   docker run -d -p 8080:80 cloudship
   ```
4. **Make changes** to `index.html`, `style.css`, or `app.js`
5. **Push** and watch CI/CD run:
   ```bash
   git add .
   git commit -m "Updated my site"
   git push
   ```
6. Go to **Actions** tab → watch the pipeline run!

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        YOUR COMPUTER                              │
│                                                                  │
│  index.html + style.css + app.js + Dockerfile                    │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────┐      ┌─────────────┐                           │
│  │ docker build │ ───▶ │ docker run  │ ──▶ http://localhost:8080 │
│  └─────────────┘      └─────────────┘                           │
└──────────────────────────────────────────────────────────────────┘
         │ git push
         ▼
┌──────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS                               │
│                                                                  │
│  ┌────────────┐   ┌──────────────┐   ┌────────────────────┐     │
│  │  Checkout  │──▶│ Docker Build  │──▶│  Push to Registry  │     │
│  └────────────┘   └──────────────┘   └────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
                                                │
                    ┌───────────────────────────┼───────────────┐
                    ▼                           ▼               ▼
          ┌──────────────┐           ┌──────────────┐  ┌─────────────┐
          │  Docker Hub   │           │   AWS ECR    │  │    GHCR     │
          │  (public)     │           │  (private)   │  │  (GitHub)   │
          └──────────────┘           └──────────────┘  └─────────────┘
                                              │
                                              ▼
                                     ┌──────────────┐
                                     │   AWS ECS    │
                                     │  (Fargate)   │
                                     │              │
                                     │  🌐 LIVE!    │
                                     └──────────────┘
```

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `port is already allocated` | Stop the existing container: `docker stop cloudship` |
| `Cannot connect to Docker daemon` | Start Docker Desktop |
| `denied: requested access to the resource` | Run `docker login` first |
| `no basic auth credentials` (ECR) | Run ECR login command again |
| `Image not found` in ECS | Check ECR URI matches task definition |
| Actions workflow not running | Check it's on `main` branch, workflow is enabled |
| ECS task keeps stopping | Check `docker logs` locally, verify port 80 |

---

## 🧹 Cleanup (AWS Resources)

After demo, delete AWS resources to avoid charges:

```bash
# Delete ECS service & cluster
aws ecs update-service --cluster cloudship-cluster --service cloudship-service --desired-count 0
aws ecs delete-service --cluster cloudship-cluster --service cloudship-service --force
aws ecs delete-cluster --cluster cloudship-cluster

# Delete ECR repository
aws ecr delete-repository --repository-name cloudship --force

# Delete security group (if created)
aws ec2 delete-security-group --group-name cloudship-sg
```

---

## 📚 Resources

- [Docker Docs — Get Started](https://docs.docker.com/get-started/)
- [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [AWS ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)

---

<p align="center">
  <b>Cloud-Based Application Development — YVC 2026</b><br>
  <sub>Made with 🐳 by Rotem Levi</sub>
</p>
