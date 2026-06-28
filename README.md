# EKS Status Page

A real-time status page application deployed on AWS EKS. Built as a DevOps portfolio project covering infrastructure provisioning, containerisation, Kubernetes, GitOps, and CI/CD.

**Live:** https://eks.virtualscale.dev

**References:**
- [Architecture Decision Records](docs/adr.md)
- [Troubleshooting](docs/troubleshooting.md)

---

## Architecture Overview

```
Internet
   │
   ▼
Cloudflare DNS (managed by ExternalDNS)
   │
   ▼
AWS NLB (created by NGINX Ingress Helm chart)
   │
   ▼
NGINX Ingress Controller
   ├── /api  →  Backend (Node.js/Express)  →  PostgreSQL
   └── /     →  Frontend (React/nginx)
```

### Infrastructure Components

| Layer | Technology |
|-------|-----------|
| Cloud | AWS (EKS, ECR, VPC, EBS, IAM) |
| IaC | Terraform (modular) |
| Container runtime | EKS managed node group (t3.medium) |
| Ingress | NGINX Ingress Controller + AWS NLB |
| TLS | CertManager + Let's Encrypt |
| DNS | ExternalDNS → Cloudflare |
| GitOps | ArgoCD |
| Monitoring | kube-prometheus-stack (Prometheus + Grafana) |
| CI | GitHub Actions + Trivy (image scan) |
| IaC security | GitHub Actions + Checkov (Terraform scan) |

### Application Stack

| Component | Technology |
|-----------|-----------|
| Frontend | React + Vite + Tailwind CSS, served by nginx |
| Backend | Node.js + Express + WebSocket |
| Database | PostgreSQL 16 |

---

## Project Structure

```
eks-statuspage/
├── app/
│   ├── backend/          # Node.js/Express API + WebSocket
│   └── frontend/         # React app + nginx config
├── docs/
│   ├── adr.md            # Architecture Decision Records
│   └── deployment-issues.md  # Issues encountered and how they were fixed
├── infrastructure/
│   └── terraform/
│       ├── bootstrap/    # S3 state bucket (run once)
│       ├── environments/
│       │   └── production/  # Root module - wires all modules together
│       └── modules/
│           ├── vpc/      # VPC, subnets, NAT gateway
│           ├── eks/      # EKS cluster + OIDC provider
│           ├── irsa/     # IAM role per service account
│           └── ecr/      # Container registries
├── kubernetes/
│   ├── base/             # Kubernetes manifests (namespace, app, ingress)
│   └── helm/             # Helm values files
│       ├── nginx-ingress/
│       ├── cert-manager/
│       ├── external-dns/
│       ├── argocd/
│       └── monitoring/
├── .github/workflows/
│   ├── terraform.yml     # Checkov scan + plan on PR, apply on merge
│   ├── ci.yml            # Build + Trivy scan + push to ECR
│   └── cd.yml            # Update image tags → ArgoCD syncs
└── docker-compose.yml    # Local development stack
```

---

## Prerequisites

- AWS account with programmatic access (IAM user with sufficient permissions)
- AWS CLI configured (`aws configure`)
- Terraform >= 1.14
- kubectl
- Helm
- Docker (for local development)
- Cloudflare account with your domain

### Required tools

```bash
aws --version
terraform --version
kubectl version --client
helm version
```

---

## Local Development

Run the full stack locally with Docker Compose:

```bash
docker compose up --build
```

| Service | URL |
|---------|-----|
| Frontend | http://localhost |
| Backend API | http://localhost:3000/api/services |
| Health check | http://localhost:3000/health |

---

## Deployment

### Step 1 - Bootstrap (run once)

Creates the S3 bucket used to store Terraform state. Run this once - the bucket has `prevent_destroy` so it survives future `terraform destroy` runs.

```bash
cd infrastructure/terraform/bootstrap
terraform init
terraform apply
```

### Step 2 - Provision infrastructure

```bash
cd infrastructure/terraform/environments/production
cp terraform.tfvars.example terraform.tfvars  # fill in your values
terraform init
terraform apply
```

Note the outputs - you will need the ECR URLs and IRSA role ARNs.

### Step 3 - Connect kubectl to EKS

```bash
aws eks update-kubeconfig --name eks-statuspage --region eu-west-2
kubectl get nodes  # verify nodes are Ready
```

### Step 4 - Add Helm repos

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Step 5 - Install Helm charts (in order)

**cert-manager:**
```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  -f kubernetes/helm/cert-manager/values.yaml
```

**NGINX Ingress:**
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  -f kubernetes/helm/nginx-ingress/values.yaml
```

**ExternalDNS** - create the Cloudflare secret first:
```bash
kubectl create namespace external-dns

kubectl create secret generic cloudflare-api-token \
  --from-literal=cloudflare_api_token=<your-cloudflare-api-token> \
  --namespace external-dns

helm install external-dns external-dns/external-dns \
  --namespace external-dns \
  -f kubernetes/helm/external-dns/values.yaml
```

**ArgoCD:**
```bash
helm install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  -f kubernetes/helm/argocd/values.yaml
```

**Monitoring:**
```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f kubernetes/helm/monitoring/values.yaml
```

### Step 6 - Install EBS CSI driver

Required for PostgreSQL persistent storage. Uses the IRSA role created by Terraform.

```bash
aws eks create-addon \
  --cluster-name eks-statuspage \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn $(cd infrastructure/terraform/environments/production && terraform output -raw irsa_ebs_csi_role_arn) \
  --region eu-west-2
```

### Step 7 - Apply Kubernetes manifests

Update the placeholder values before applying:
- `kubernetes/base/backend/serviceaccount.yaml` - replace `<irsa_backend_role_arn>` with Terraform output
- `kubernetes/base/backend/deployment.yaml` - replace `<ecr_registry>` with ECR URL
- `kubernetes/base/frontend/deployment.yaml` - replace `<ecr_registry>` with ECR URL

Then apply:

```bash
kubectl apply -f kubernetes/base/namespace.yaml
kubectl apply -f kubernetes/base/secret.yaml
kubectl apply -f kubernetes/base/postgres/
kubectl apply -f kubernetes/base/backend/
kubectl apply -f kubernetes/base/frontend/
kubectl apply -f kubernetes/base/cert-manager/
kubectl apply -f kubernetes/base/ingress.yaml
kubectl apply -f kubernetes/base/argocd/
```

### Step 8 - Set up GitHub Actions secrets

Add these secrets in GitHub → Settings → Secrets and variables → Actions:

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_ACCOUNT_ID` | Your AWS account ID |

Trigger the first CI build:

```bash
git commit --allow-empty -m "ci: trigger image build"
git push origin main
```

---

## CI/CD Pipeline

```
Push to main (app/**)
   │
   ▼
CI workflow - build images → Trivy scan → push to ECR
   │
   ▼
CD workflow - update image tags in manifests → commit to Git
   │
   ▼
ArgoCD - detects Git change → syncs cluster
```

| Workflow | Trigger | Actions |
|----------|---------|---------|
| Terraform | PR or push to `infrastructure/terraform/**` | fmt + validate + Checkov + plan (PR) / apply (main) |
| CI | PR or push to `app/**` | Build + Trivy scan + push to ECR (main only) |
| CD | CI completes on main | Update image tags + commit → ArgoCD syncs |

---

## Access

| Service | URL | Credentials |
|---------|-----|-------------|
| Status page | https://eks.virtualscale.dev | - |
| ArgoCD | https://argocd.virtualscale.dev | admin / see below |
| Grafana | https://grafana.virtualscale.dev | admin / changeme |

Get ArgoCD admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## Teardown

```bash
# Uninstall Helm charts first - removes the NLB before VPC is destroyed
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall argocd -n argocd
helm uninstall monitoring -n monitoring
helm uninstall external-dns -n external-dns
helm uninstall cert-manager -n cert-manager

# Delete EBS CSI addon
aws eks delete-addon --cluster-name eks-statuspage \
  --addon-name aws-ebs-csi-driver --region eu-west-2

# Destroy infrastructure
cd infrastructure/terraform/environments/production
terraform destroy
```

> The S3 state bucket is not destroyed (`prevent_destroy = true`). Delete it manually in the AWS console if no longer needed.
