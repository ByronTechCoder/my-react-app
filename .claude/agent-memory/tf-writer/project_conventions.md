---
name: project-conventions
description: Terraform layout, provider pinning, and CloudFront/S3 design decisions used in this repo's terraform/ directory
metadata:
  type: project
---

This repo (`my-react-app`) provisions S3 + CloudFront for a CRA static site via `terraform/` (created 2026-08-20, regenerated from scratch same day after the directory was found missing/untracked — the whole `terraform/` dir is `?? ` in git status, so it has never been committed; confirm with the user before assuming it persists between sessions). Key decisions to stay consistent with on future edits:

- Provider pin: `hashicorp/aws ~> 6.61` (confirmed 6.61.0 is latest via the terraform MCP `get_latest_provider_version` tool as of 2026-08-20 — re-check before bumping the constraint).
- `required_version = ">= 1.5"` in `providers.tf`.
- File layout matches the standard convention: `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `backend.tf`.
- `backend.tf` ships with the S3 backend block **commented out**, with instructions to `terraform init` locally first, apply, create the state bucket + DynamoDB lock table out-of-band, then uncomment and `terraform init -migrate-state`. Don't wire up a live backend without the user explicitly providing the state bucket/table names.
- S3 bucket name is `${project_name}-${environment}-${account_id}` (via `data.aws_caller_identity.current.account_id`) — avoids needing a `random_id` resource while guaranteeing global uniqueness.
- CloudFront uses OAC (`aws_cloudfront_origin_access_control`), never legacy OAI. Bucket policy grants `cloudfront.amazonaws.com` service principal `s3:GetObject` scoped with an `AWS:SourceArn` condition on the distribution ARN — least privilege, no wildcards.
- Cache policy is looked up via `data "aws_cloudfront_cache_policy" "caching_optimized"` (name `Managed-CachingOptimized`) rather than hardcoding the managed policy ID — same pattern should be used for other managed CloudFront policies if added later.
- Custom error response maps 404 -> `/index.html` with response_code 200, to support client-side routing (React Router) even though this app doesn't have routing yet — matches the CLAUDE.md framing of this as a React SPA.
- `viewer_certificate` TLS 1.2 minimum gotcha: AWS/Terraform **rejects** setting `minimum_protocol_version` when `cloudfront_default_certificate = true` (verified against the `aws_cloudfront_distribution` provider docs — "Can only be set if cloudfront_default_certificate = false"). So the config conditionally uses the default cert (TLS forced to TLSv1 by AWS, no override possible) when `domain_name` is empty, and a custom ACM cert + `sni-only` + `TLSv1.2_2021` when `domain_name` is set. Added an `acm_certificate_arn` variable (not explicitly requested in the original spec) to make the custom-domain path actually functional — flag this addition if a future spec claims to be "exact" and doesn't mention it.
- Versioning is enabled on the site content bucket itself (not just a future state bucket) as a rollback safety net — deviates slightly from the generic instruction that only mentions versioning for "state buckets," treated as an additional best practice rather than a contradiction.
- `aws_s3_bucket_ownership_controls` set to `BucketOwnerEnforced` (disables ACLs entirely) since access is only ever granted via bucket policy — pairs with `aws_s3_bucket_public_access_block` (all four flags true).
- Ran `terraform init -backend=false` + `terraform validate` + `terraform fmt` locally after generation (terraform CLI is available at `/usr/bin/terraform`) — do this again after any structural edit.
- Unrelated: this machine also has a separate static-HTML "portfolio site" Terraform project with its own CLAUDE.md/agents — don't conflate the two when generating for `my-react-app`.
