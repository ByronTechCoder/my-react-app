output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution serving the site (used for cache invalidation in CI/CD)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "Default CloudFront domain name (*.cloudfront.net) for the distribution."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the built site content."
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket hosting the built site content."
  value       = aws_s3_bucket.site.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions via OIDC. Set this as the AWS_ROLE_ARN repo secret."
  value       = aws_iam_role.github_actions_deploy.arn
}
