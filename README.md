# infrastructure-live

Live infrastructure configurations for a multi-environment AWS platform, managed with Terragrunt and deployed through a verified CI/CD pipeline.

This repo is the deployment target for [infrastructure-modules](https://github.com/musaumakau/infrastructure-modules). Modules are defined there. Environment-specific configurations and deployment orchestration live here.

---

## How It Works

Changes flow through a pipeline that verifies what gets deployed matches exactly what was reviewed:

```
PR merges to infrastructure-modules
  └── dispatch fires with commit SHA
      └── infrastructure-live: gate runs
          └── fetch PR manifest from S3
          └── re-plan against live state
          └── compare — match: deploy / mismatch: stop
              └── Dev deploys automatically
              └── Staging deploys automatically
                  └── Prod pauses for human approval
                      └── approved: apply
                      └── rejected: stop
```

The manifest written at PR time is the contract. The gate enforces it at deploy time. What you reviewed is what gets applied.

---

## Repository Structure

```
infrastructure-live/
├── root.hcl                   ← root config: backend, provider, common inputs
├── Dev/
│   ├── env.hcl                ← environment-specific variables
│   ├── vpc/
│   ├── eks/
│   └── kubernetes-addons/
├── Staging/
│   ├── env.hcl
│   ├── vpc/
│   ├── eks/
│   └── kubernetes-addons/
├── Prod/
│   ├── env.hcl
│   ├── vpc/
│   ├── eks/
│   └── kubernetes-addons/
├── shared/
│   └── cicd-state/            ← provisions the S3 bucket for plan manifests — written by infrastructure-modules CI, read by the deploy gate here
└── .github/
    ├── actions/
    │   ├── aws-auth/          ← OIDC credential configuration
    │   ├── terragrunt-setup/  ← Terraform + Terragrunt installation
    │   └── eks-kubeconfig/    ← EKS cluster name resolution + kubectl config
    └── workflows/
        ├── terragrunt-deploy.yml   ← main deployment pipeline
        └── terragrunt-destroy.yml  ← manual teardown with approval gates
```

---

## Deployment Pipeline

### Triggers

| Event | Target | Behaviour |
|-------|--------|-----------|
| `repository_dispatch: trigger-deploy` | Dev | Automatic, fired by infrastructure-modules on merge to main |
| `repository_dispatch: trigger-staging` | Staging | Automatic, fired after successful Dev deploy |
| `repository_dispatch: trigger-prod` | Prod | Fires after Staging, pauses for approval |
| `workflow_dispatch` | Any | Manual re-runs |

### Plan Comparison Gate

Before every deploy, the gate job runs per module:

1. Fetches the plan manifest from S3, keyed by commit SHA
2. Re-plans against live state
3. Compares resource addresses and actions against what was reviewed on the PR
4. For security-sensitive resource types (`aws_security_group`, `aws_iam_role`, `aws_s3_bucket`), also checks for critical property drift — ingress rules, IAM policies, encryption config, and public access settings

Environment-specific drift thresholds:

| Environment | Warn threshold | Block threshold |
|-------------|----------------|-----------------|
| Dev | 30 | never (observe only) |
| Staging | 30 | 70 |
| Prod | 20 | 40 |

If the gate detects unreviewed resources or critical property drift, the deploy stops before a single `apply` runs.

### Deploy Order

```
vpc → eks → kubernetes-addons
```

### Promotion Chain

```
Dev success → trigger-staging → Staging success → trigger-prod → Prod (approval required)
```

SHA travels in every dispatch payload. The same manifest verified at Dev is verified again at Staging and Prod.

### Production Approval

Prod deploys target the `production-approval` GitHub environment. The deploy job pauses after the gate runs — the reviewer sees drift scores and resource changes before approving. Approval is never blind.

---

## Destroy Pipeline

Manual only. Tears down infrastructure in reverse deploy order:

```
kubernetes-addons → eks → vpc
```

Requires typing the environment name to confirm before anything runs.

| Environment | Gate |
|-------------|------|
| Dev | None — runs immediately |
| Staging | `staging-approval` environment — required reviewers |
| Prod | `production-approval` environment — required reviewers |

Destroy and deploy share a concurrency group — they can never run simultaneously against the same environment.

---

## Composite Actions

All setup logic is extracted into composite actions. No copy-paste across jobs.

| Action | Purpose |
|--------|---------|
| `aws-auth` | OIDC credential configuration. No long-lived keys. Role ARN passed as input — supports multiple accounts and roles. |
| `terragrunt-setup` | Installs Terraform and Terragrunt at pinned versions. No plugin cache — infrastructure-live applies modules sequentially so per-module cache keys don't apply. |
| `eks-kubeconfig` | Fetches EKS cluster name from Terragrunt output and configures kubectl. Verifies node access before returning. |

---

## Security

- **OIDC authentication** — every job assumes an IAM role via OpenID Connect. No AWS access keys stored as secrets.
- **SHA-pinned actions** — every `uses:` reference is pinned to a commit SHA. Tags can be force-pushed; SHAs cannot.
- **Environment protection rules** — Staging and Prod deployments and destroys require explicit human approval via GitHub environment protection rules.
- **Concurrency guards** — deploy and destroy share a concurrency group per environment. Partial state from concurrent runs is not possible.
- **Confirmation input on destroy** — the environment name must be typed explicitly before a destroy job starts.

---

## Infrastructure

| Component | Details |
|-----------|---------|
| EKS | Cluster with IRSA, private endpoint, logging enabled |
| VPC | Public/private subnets, NAT gateway, IGW |
| Kubernetes Addons | AWS Load Balancer Controller, Cert Manager, Cluster Autoscaler, EBS CSI Driver, External DNS, External Secrets, KEDA, Kube Prometheus Stack (Grafana, Prometheus, Alertmanager), Loki, Metrics Server |
| Cloud | AWS `eu-west-1` |
| IaC | Terraform `1.7.5`, Terragrunt `0.84.1` |

Modules are defined in [infrastructure-modules](https://github.com/musaumakau/infrastructure-modules). This repo contains environment-specific configurations only.

---

## Related

- **infrastructure-modules** — reusable Terraform modules, CI pipeline, blast radius scoring, plan manifests
- **Medium** — write-ups covering the pipeline architecture, manifest-as-contract deployment pattern, and CI modularization: [@musaujoseph8](https://medium.com/@musaujoseph8)