# Core + provider pins; tenv resolves the runtime from required_version
# (claude/rules/tools/terraform.md). Backend endpoint and credentials come
# from the environment (AWS_ENDPOINT_URL_S3, AWS_ACCESS_KEY_ID,
# AWS_SECRET_ACCESS_KEY — derived in .envrc) so no account identifier lands
# in this public repo; client-side encryption is enforced via TF_ENCRYPTION,
# also built by .envrc. See ADR-0022.

terraform {
  required_version = "~> 1.12"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }

  backend "s3" {
    bucket       = "tofu-state"
    key          = "repos/terraform.tfstate"
    region       = "auto"
    use_lockfile = true

    # R2 is S3-compatible, not AWS — skip every AWS-ism.
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}

provider "github" {
  owner = "carpet-stain"
}
