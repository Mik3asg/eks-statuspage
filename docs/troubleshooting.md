# Troubleshooting

Each entry follows the same structure: **Symptom → Root Cause → Fix**.

---

## Issue 001 - Docker build failed with `npm ci`

**Symptom:**
`docker compose up --build` failed with `npm ci` error inside the backend and frontend containers.

**Root Cause:**
`npm ci` requires a `package-lock.json` file to exist. The file was not committed to the repository.

**Fix:**
Changed `npm ci` to `npm install --omit=dev` in both Dockerfiles. `npm install` generates the lock file if missing; `--omit=dev` excludes development dependencies from the production image.

---

## Issue 002 - EKS cluster creation failed with unsupported Kubernetes version

**Symptom:**
`terraform apply` failed with `InvalidParameterException: unsupported Kubernetes version 1.29`.

**Root Cause:**
Kubernetes 1.29 reached end-of-life and was removed from EKS. The default `cluster_version` variable was set to `1.29`.

**Fix:**
Updated `cluster_version` default in `variables.tf` from `1.29` to `1.32`.

---

## Issue 003 - EKS cluster deployed in wrong AWS region (eu-west-1 instead of eu-west-2)

**Symptom:**
Terraform outputs showed the cluster endpoint URL containing `eu-west-1` instead of `eu-west-2`.

**Root Cause:**
`terraform.tfvars` had `aws_region = "eu-west-1"` which overrode the `eu-west-2` default in `variables.tf`.

**Fix:**
Ran `terraform destroy`, updated `terraform.tfvars` to `aws_region = "eu-west-2"`, then re-ran `terraform apply`.

---

## Issue 004 - `terraform destroy` failed on VPC subnets and Internet Gateway

**Symptom:**
`terraform destroy` timed out with `DependencyViolation` errors when deleting the public subnets and Internet Gateway.

**Root Cause:**
The NGINX ingress Helm chart created an AWS Network Load Balancer (NLB) in the public subnets. The NLB was not deleted when the EKS cluster was destroyed because Kubernetes was no longer running to clean it up.

**Fix:**
Manually deleted the NLB via AWS CLI (`aws elbv2 delete-load-balancer`), then re-ran `terraform destroy`.

**Prevention:**
Always uninstall Helm charts (`helm uninstall ingress-nginx`) before running `terraform destroy` so Kubernetes can clean up the NLB.

---

## Issue 005 - EBS CSI driver in CrashLoopBackOff, postgres PVC stuck Pending

**Symptom:**
`kubectl get pods -n kube-system | grep ebs` showed the controller in `CrashLoopBackOff`.
`kubectl get pvc -n production` showed `postgres-pvc` in `Pending` state.

**Root Cause:**
The EBS CSI driver addon was installed without an IRSA role. Without AWS credentials, the driver could not call `ec2:DescribeAvailabilityZones` or `ec2:CreateVolume`. It fell back to EC2 IMDS which is not available on EKS worker nodes by default.

**Fix:**
1. Created a dedicated IRSA role (`irsa_ebs_csi`) in Terraform with the `AmazonEBSCSIDriverPolicy` managed policy.
2. Recreated the addon with the IRSA role ARN attached:
   ```
   aws eks create-addon --addon-name aws-ebs-csi-driver \
     --service-account-role-arn <irsa_ebs_csi_role_arn>
   ```

---

## Issue 006 - Postgres pod stuck Pending due to EBS volume AZ conflict

**Symptom:**
`kubectl describe pod postgres-... -n production` showed:
`1 node(s) had volume node affinity conflict`.

**Root Cause:**
The PVC was initially bound to a node in `eu-west-2b`. When nodes became full and a new node was added, it was placed in `eu-west-2a`. EBS volumes are AZ-specific - they can only attach to nodes in the same AZ. The new node was in the wrong AZ.

**Fix:**
Deleted the PVC (`kubectl delete pvc postgres-pvc -n production`) and re-applied it. With no pre-existing volume, the scheduler could provision a new EBS volume in the correct AZ for the node it chose.

---

## Issue 007 - Postgres failed to initialise: `directory is not empty`

**Symptom:**
`kubectl logs postgres-... -n production` showed:
`initdb: error: directory "/var/lib/postgresql/data" exists but is not empty`
`It contains a lost+found directory`

**Root Cause:**
When an EBS volume is formatted with EXT4, the OS creates a `lost+found` directory at the filesystem root. PostgreSQL refuses to initialise if its data directory contains any files or directories.

**Fix:**
Added the `PGDATA` environment variable to the postgres deployment:
```yaml
- name: PGDATA
  value: /var/lib/postgresql/data/pgdata
```
PostgreSQL now initialises inside a subdirectory, leaving `lost+found` untouched at the root.

---

## Issue 008 - Pods stuck Pending: `Too many pods`

**Symptom:**
`kubectl describe pod` showed: `0/2 nodes are available: 2 Too many pods`.

**Root Cause:**
`t3.medium` instances support a maximum of ~17 pods per node due to ENI and IP address limits. With all Helm charts installed (cert-manager, NGINX, ExternalDNS, ArgoCD, kube-prometheus-stack), both nodes reached capacity before the application pods could be scheduled.

**Fix:**
Scaled the node group from 2 to 3 nodes:
```
aws eks update-nodegroup-config \
  --scaling-config minSize=1,maxSize=3,desiredSize=3
```

---

## Issue 009 - CD pipeline rejected git push (403 Forbidden)

**Symptom:**
GitHub Actions CD pipeline failed when trying to push updated image tags back to the repository.

**Root Cause:**
`GITHUB_TOKEN` has read-only permissions by default. Writing commits back to the repository requires `contents: write`.

**Fix:**
Added permissions block to the CD workflow:
```yaml
permissions:
  contents: write
```

---

## Issue 010 - Frontend deployment YAML parse error

**Symptom:**
`kubectl apply -f kubernetes/base/frontend/deployment.yaml` failed with:
`error converting YAML to JSON: yaml: line 21: could not find expected ':'`

**Root Cause:**
Missing space after the `image:` key - `image:207137...` instead of `image: 207137...`. YAML requires a space between the key and value.

**Fix:**
Added the missing space: `image: 207137402976.dkr.ecr.eu-west-2.amazonaws.com/eks-statuspage/frontend:latest`

---

## Issue 011 - ArgoCD ingress hostname showing `argocd.example.com`

**Symptom:**
`kubectl get ingress -n argocd` showed `HOSTS: argocd.example.com` despite setting `server.ingress.hosts` in the Helm values.

**Root Cause:**
Newer versions of the `argo-cd` Helm chart use `global.domain` as the canonical hostname source. The `server.ingress.hosts` list is ignored without it.

**Fix:**
Added `global.domain: argocd.virtualscale.dev` to the ArgoCD Helm values and upgraded the release.

---

## Issue 012 - GitHub Actions Terraform pipeline failing with missing credentials

**Symptom:**
Terraform workflow in GitHub Actions failed with:
`Credentials could not be loaded from any providers`

**Root Cause:**
The GitHub Actions secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) had not been added to the repository before the first pipeline run was triggered.

**Fix:**
Added the three required secrets in GitHub → Settings → Secrets and variables → Actions:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`
