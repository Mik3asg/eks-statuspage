# We need to create in the EKS modules, the following:
- aws_eks_cluster                       # the control plane
- aws_eks_node_group                    # the worker nodes
- aws_iam_role                          # for the cp
- aws_iam_role                          # for the worker nodes
- aws_iam_role_policy_attachment        # (x2 for cp, x3 for wrk nodes)

---
Q1 - The EKS control plane needs an IAM role — what does that role allow, and why does EKS need it?
A1 - Control Plane Role -> Lets AWS manage EJS on your behalf. Policy: Attached the 'AmazonEKSClusterPolicy' managed policy

Q2 - The worker nodes also need their own IAM role — what's the difference between the control plane role and the node role?
A2 - Node Role -> Lets EC2 worker nodes join the cluster and puill images. 3 policies:
    - 'AmazonEKSWorkerNodePolicy'
    - 'AmazonEKS_CNI_Policy'
    - 'AmazonEC2ContainerRegistryReadOnly'

Q3 - What's a managed node group, and why use it over self-managed nodes?
A3 - Managed node groups - AWS handles EC2 lifecycle. Self-managed = you handle it.

---

The problem OIDC solves
Pods running in your cluster sometimes need to call AWS APIs — e.g. your backend reading from S3, or the load balancer controller creating ALBs. The naive solution is to stick AWS credentials in a Secret or give the EC2 node a broad IAM role. Both are bad: credentials leak, and a node role grants every pod on that node the same permissions.

IRSA (IAM Roles for Service Accounts) is the proper fix: a specific pod gets a specific IAM role, nothing else.

What OIDC is
OIDC (OpenID Connect) is an identity protocol built on OAuth2. It lets one system say "I vouch that this identity is who they claim to be" using a signed JWT token.

EKS runs a built-in OIDC identity provider. When a pod starts, Kubernetes mounts a signed JWT into it — essentially a token that says:

"This is the service account my-app in namespace production, signed by the EKS cluster at https://oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLID"

How AWS uses it
You register that EKS OIDC issuer URL as a trusted identity provider in IAM. Then you write an IAM role trust policy like:


{
  "Principal": { "Federated": "arn:aws:iam::123456789:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLID" },
  "Condition": {
    "StringEquals": {
      "oidc.eks.../id/EXAMPLID:sub": "system:serviceaccount:production:my-app"
    }
  }
}
When the pod calls sts:AssumeRoleWithWebIdentity, AWS validates the JWT signature against the OIDC provider, checks the condition, and if it matches — issues temporary credentials for that role only.

Why we output the URL
The irsa/ module needs to:

Create an aws_iam_openid_connect_provider resource — registers the EKS cluster as a trusted OIDC provider in your AWS account
Build trust policies scoped to specific service accounts
Both require the issuer URL as input. Without it, irsa/ has no way to know which cluster to trust or how to construct the ARN of the provider.

One-liner mental model: OIDC lets your pods prove their identity to AWS without storing any credentials — the cluster itself is the trusted authority.

main.tf
explain in simple terms in 2 lines what and why and how
EKS gives every pod a signed "ID card" (JWT). OIDC lets AWS read that card and say "yes, this pod is allowed to assume this IAM role" — no hardcoded credentials needed.

provide a mental map for the current challenge, the pb we are solving, how and why
Mental map — Pod Identity on EKS

THE PROBLEM
  Pods need AWS access (S3, RDS, ECR...)
  ❌ Option A: hardcode credentials → leak risk
  ❌ Option B: broad node IAM role → every pod on node gets same access
  ✅ Option C: IRSA — pod gets its own scoped IAM role, no credentials stored

HOW IT WORKS
  EKS OIDC Provider              IAM
  (built into cluster)           (AWS)
        │                          │
        │  1. Pod starts           │
        │     → K8s mounts JWT     │
        │        "I am sa/my-app"  │
        │                          │
        │  2. Pod calls STS ───────▶ AssumeRoleWithWebIdentity
        │                          │
        │  3. AWS verifies JWT ◀───┤ checks OIDC provider signature
        │     + checks condition:  │ "is this really sa/my-app?"
        │                          │
        │  4. STS returns ◀────────┤ temp credentials for that role only
        │     short-lived creds    │

WHY THE OIDC ISSUER URL MATTERS
  AWS needs to know WHICH cluster to trust
  → irsa/ registers the URL as a trusted identity provider in IAM
  → trust policy scopes the role to one specific service account
  → no other pod / cluster can assume that role
One rule to remember: the cluster is the authority, the JWT is the proof, STS is the gatekeeper.

what means pod gets its own scoped IAM role, rephrase in simple terms
Instead of giving every pod on a node the same front-door key, each pod gets its own key that only opens the doors it needs.