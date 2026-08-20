# ---------------------------------------------------------------------------
# GitHub Actions OIDC federation — lets the CI/CD workflow assume an AWS IAM
# role via short-lived tokens instead of long-lived access keys.
# ---------------------------------------------------------------------------

# Fetched dynamically rather than hardcoded: AWS validates the cert chain
# against its own trusted CA bundle for GitHub's OIDC endpoint, so the
# thumbprint value itself is effectively unused during STS calls, but the
# field is still required at creation time. Pulling it live avoids the
# well-known "stale thumbprint" breakage that hardcoding causes when GitHub
# rotates its intermediate CA.
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# IAM role assumed by the GitHub Actions workflow via OIDC. Trust policy is
# scoped to this exact repo + the main branch only, so pull requests and
# other branches cannot assume this role.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ByronTechCoder@${var.github_org_id}/my-react-app@${var.github_repo_id}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.project_name}-${var.environment}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Least-privilege permissions: sync build/ to the site bucket and invalidate
# the CloudFront cache. Nothing else.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid    = "S3DeploySiteContent"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }

  statement {
    sid       = "CloudFrontInvalidateCache"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.project_name}-${var.environment}-github-actions-deploy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}
