# infrastructure-live

Everything's structured for **reusability, readability, and real-world scale**.

---

## 🔧 Why Terragrunt?

Because I like my infrastructure like I like my shell scripts — **dry and clean**.

- Reusable modules for EKS, VPC, and add-ons
- Regional/environment overrides handled gracefully
- Centralized backends, minimal duplication
- Easy to extend across **clients**, **regions**, or **projects**

---

## 🚀 What This Setup Handles (So Far)

- 🔹 EKS cluster deployment (with sane defaults and IRSA baked in)
- 🔹 ECS on Fargate (config-ready to plug in)
- 🔹 VPC with public/private subnets, NAT, IGW, etc.
- 🔹 Kubernetes Add-ons: CoreDNS, Cluster Autoscaler, Metrics Server
- 🔹 Multi-environment layering (Dev, Staging, etc.)
- 🔹 Secure, production-grade configs following AWS best practices

---

## 📦 Future Enhancements

- 🛠️ Karpenter setup for dynamic scaling
- 📊 CloudWatch dashboards via Terraform
- 🐳 ECS workload blueprints
- ☁️ GitHub Actions CI/CD integration
- 💸 FinOps considerations (Spot support, Graviton, tagging, budgets)

---

## 📣 Who Is This For?

Whether you're:
- A team scaling across **multiple AWS regions**
- Supporting **multiple clients** with isolated environments
- Or just someone who’s tired of spaghetti infrastructure files...

This repo brings **order, automation, and clarity** to your AWS deployments.

---

## 🤝 Work With Me

This structure reflects how I approach DevOps — clean, scalable, and built to evolve.  
Need help building something similar? Let's talk.

---


