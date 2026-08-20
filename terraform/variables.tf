variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used as a prefix for resource names and in tags."
  type        = string
  default     = "my-react-app"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens (required for S3 bucket naming)."
  }
}

variable "environment" {
  description = "Deployment environment name (e.g. production, staging), used in resource names and tags."
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Custom domain name to serve the site from via CloudFront (e.g. www.example.com). Leave empty to use the default *.cloudfront.net domain."
  type        = string
  default     = ""
}

# Not in the original request, but required to make the `domain_name` path functional:
# CloudFront rejects a custom `minimum_protocol_version` unless a non-default (ACM) certificate
# is attached. If domain_name is set without an ACM cert, the distribution falls back to the
# CloudFront default certificate and TLS 1.2 enforcement is skipped. Must be an ACM certificate
# issued in us-east-1 (CloudFront requirement), regardless of var.region.
variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate (issued in us-east-1) covering domain_name. Required only if domain_name is set."
  type        = string
  default     = ""
}
