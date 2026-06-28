# Architecture Decision Records (ADR)

Each ADR captures a key design choice, the context behind it, and the trade-off accepted.

---

## ADR-001 - DNS managed by ExternalDNS, not Terraform

**Status:** Accepted

**Context:**
DNS records for `eks.virtualscale.dev` need to point to the NLB created by the NGINX ingress controller. The NLB hostname is only known after the cluster is running.

**Decision:**
Use ExternalDNS (Helm chart) to manage Cloudflare DNS automatically from Ingress annotations. Remove the Terraform `dns/` module.

**Reason:**
Terraform cannot reference the NLB hostname at plan time - it doesn't exist yet. ExternalDNS watches the cluster and creates/updates DNS records dynamically when an Ingress is created or updated.

**Trade-off:**
DNS is no longer managed as infrastructure-as-code. Accepted because it is the standard GitOps pattern for dynamic ingress hostnames.

---

## ADR-002 - S3 native state locking, no DynamoDB

**Status:** Accepted

**Context:**
Terraform state must be locked to prevent concurrent applies from corrupting the state file.

**Decision:**
Use S3 native locking (`use_lockfile = true`, Terraform ≥ 1.10) instead of a DynamoDB lock table.

**Reason:**
Fewer AWS resources to manage. S3 native locking is the modern approach and removes the operational overhead of a DynamoDB table.

**Trade-off:**
Requires Terraform ≥ 1.10. Not backwards compatible with older Terraform versions.

---

## ADR-003 - NGINX Ingress over AWS ALB

**Status:** Accepted

**Context:**
The cluster needs a single entry point for HTTP/HTTPS traffic.

**Decision:**
Use NGINX Ingress Controller (Helm) exposed via an AWS Network Load Balancer (NLB).

**Reason:**
NGINX is provider-agnostic, widely supported, and integrates natively with CertManager and ExternalDNS. ALB requires the AWS Load Balancer Controller add-on and is AWS-specific.

**Trade-off:**
An extra network hop (NLB → NGINX → service) compared to ALB direct routing. Accepted for portability and simplicity.

---

## ADR-004 - IRSA per service account over node-level IAM

**Status:** Accepted

**Context:**
Pods may need AWS permissions (e.g. EBS CSI driver, future S3 access).

**Decision:**
Use IRSA (IAM Roles for Service Accounts) - one IAM role per Kubernetes service account, scoped via OIDC condition.

**Reason:**
Node-level IAM gives every pod on the node the same AWS permissions. IRSA scopes permissions to a specific pod identity - least privilege principle.

**Trade-off:**
More complex setup (OIDC provider, role per service account). Accepted as it is the AWS-recommended production pattern.

---

## ADR-005 - OIDC provider lives in the EKS module, not the IRSA module

**Status:** Accepted

**Context:**
IRSA requires an OIDC provider registered in IAM. The IRSA module is called multiple times (once per service account).

**Decision:**
Create the OIDC provider inside the `eks/` module and pass its ARN to each `irsa/` module call.

**Reason:**
AWS only allows one OIDC provider per cluster endpoint. If the OIDC provider were created inside the IRSA module, the second module call would conflict and fail.

**Trade-off:**
The EKS module now owns a resource that conceptually belongs to IAM. Accepted to avoid resource conflicts.

---

## ADR-006 - ArgoCD for GitOps CD, not direct kubectl

**Status:** Accepted

**Context:**
Application deployments need to be automated after a CI build.

**Decision:**
The CD pipeline commits updated image tags to Git. ArgoCD detects the change and syncs the cluster to match.

**Reason:**
Git becomes the single source of truth. Manual `kubectl apply` is error-prone and leaves no audit trail. ArgoCD provides drift detection and automatic self-healing.

**Trade-off:**
Adds ArgoCD as an operational dependency. Accepted as it is the standard GitOps pattern.

---

## ADR-007 - EBS CSI driver uses IRSA, not node IAM

**Status:** Accepted

**Context:**
The EBS CSI driver needs `ec2:CreateVolume` and related permissions to provision PersistentVolumes.

**Decision:**
Create a dedicated IRSA role for the `ebs-csi-controller-sa` service account with the `AmazonEBSCSIDriverPolicy` managed policy.

**Reason:**
Attaching the EBS CSI policy to the node IAM role would grant every pod on every node the ability to create EBS volumes. IRSA limits this to the CSI controller only.

**Trade-off:**
Additional IAM role and Terraform module call. Accepted for least-privilege compliance.
