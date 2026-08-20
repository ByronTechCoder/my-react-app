---
name: open-findings
description: Outstanding (unfixed) security findings from the 2026-08-20 terraform audit — verify still present before citing, since the user may have applied fixes since.
metadata:
  type: project
---

As of the 2026-08-20 audit, these were open and not yet remediated. Re-check the
actual files before assuming still true — this is a snapshot, not a live state.

- MEDIUM: No `aws_cloudfront_response_headers_policy` attached to the CloudFront
  distribution in `terraform/main.tf` — no CSP, X-Frame-Options, X-Content-Type-Options,
  Referrer-Policy, or HSTS security headers are set on responses.
- MEDIUM: `terraform/backend.tf` has the S3+DynamoDB remote backend entirely commented
  out ("currently disabled" per the file's own comments) — state is local. Documented
  as an intentional bootstrapping step (chicken-and-egg: can't create the state bucket
  from the config that needs state to exist), but it's an open risk until the bootstrap
  bucket/table are actually created and the backend block uncommented + migrated.
- LOW: No CloudFront access logging (`logging_config` block) and no S3 server access
  logging configured — no audit trail of requests if needed for incident investigation.
- LOW: No WAF (`aws_wafv2_web_acl`) associated with the CloudFront distribution.
  Reasonable to deprioritize given this is a static public portfolio site with no
  backend/API surface, but worth revisiting if the site ever adds forms/endpoints.
- LOW/informational: S3 SSE uses AES256 (SSE-S3) rather than SSE-KMS. Not a real gap
  for this use case (public static content, no sensitive data) — only worth raising if
  compliance requirements change.

No CRITICAL or HIGH findings as of this audit — see [[terraform-baseline]] for what's
already correctly implemented (OAC, bucket policy SourceArn scoping, OIDC trust
condition scoping, least-privilege IAM, no hardcoded secrets/ARNs).
