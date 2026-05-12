terraform {
  source = "git::https://${get_env("REPO_DISPATCH_PAT", "")}@github.com/musaumakau/infrastructure-modules.git//cicd-state?ref=cicd-state-v0.0.1"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  project_name = "musaumakau"
  oidc_role_arn = "arn:aws:iam::649203810550:role/EksOIDCRole"

  manifest_retention_days           = 90
  noncurrent_version_retention_days = 30
  kms_deletion_window_days          = 7

  tags = {
    ManagedBy = "terraform"
    Repo      = "infrastructure-live"
  }
}