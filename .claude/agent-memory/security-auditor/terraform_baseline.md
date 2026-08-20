---
name: terraform-baseline
description: Known-good security patterns already implemented in terraform/ as of 2026-08-20 audit — use to spot drift/regressions in future reviews rather than re-deriving from scratch.
metadata:
  type: project
---

As of the 2026-08-20 audit, `terraform/` (main.tf, github-oidc.tf, backend.tf, providers.tf,
outputs.tf, variables.tf) implements these patterns correctly. Future audits should
diff against this baseline rather than re-explaining why each is correct — only flag
if one of these has regressed.

- S3 bucket (`aws_s3_bucket.site`): `aws_s3_bucket_public_access_block` blocks all
  four public-access vectors; `aws_s3_bucket_ownership_controls` uses
  `BucketOwnerEnforced` (ACLs disabled entirely, not just blocked); SSE-S3 (AES256)
  encryption at rest; versioning enabled.
- CloudFront origin uses `bucket_regional_domain_name` (REST endpoint) + OAC
  (`aws_cloudfront_origin_access_control`), NOT the S3 static-website endpoint and
  NOT legacy OAI. This is the correct/modern pattern — do not flag OAC usage itself.
- S3 bucket policy scopes access to CloudFront via `AWS:SourceArn` condition tied to
  the specific distribution ARN (confused-deputy protection) — not just
  `Service: cloudfront.amazonaws.com` alone.
- `viewer_protocol_policy = "redirect-to-https"` on the default cache behavior —
  HTTP→HTTPS redirect satisfied.
- GitHub OIDC trust policy (`github-oidc.tf`, `data.aws_iam_policy_document.github_actions_assume_role`)
  uses `StringEquals` (not `StringLike`) on both the `aud` claim and the `sub` claim,
  scoped to `repo:ByronTechCoder/my-react-app:ref:refs/heads/main` — properly scoped
  to one repo AND one branch, not a wildcard like `repo:org/*`. See [[repo-identity]].
- IAM deploy policy (`aws_iam_role_policy.github_actions_deploy`) has no wildcards in
  actions or resources — scoped to the specific S3 bucket ARN + `/*` and the specific
  CloudFront distribution ARN, only the 4 S3 actions and 1 CloudFront action actually
  needed for CI/CD (sync + invalidate).
- No hardcoded account IDs/ARNs anywhere — account ID pulled via
  `data.aws_caller_identity.current`, distribution/bucket ARNs referenced via
  resource attributes.
- `tls_certificate` data source used to fetch the GitHub OIDC thumbprint dynamically
  rather than hardcoding it (avoids stale-thumbprint breakage on GitHub CA rotation).
- Provider versions pinned with pessimistic constraints (`~> 6.61`, `~> 4.3`) and a
  committed `.terraform.lock.hcl` with hashes — acceptable pinning, not floating.
