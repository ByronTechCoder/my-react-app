# ---------------------------------------------------------------------------
# Remote state backend (S3 + DynamoDB lock table) — currently disabled.
#
# This project does not yet provision its own state bucket/lock table (doing
# so from within this same configuration would create a chicken-and-egg
# problem: you'd need state to exist before you can create the thing that
# stores state). Bootstrap sequence:
#
#   1. Leave this block commented out. Run `terraform init` (local state)
#      and `terraform apply` as normal for the resources in this directory.
#   2. Separately (e.g. via the AWS console/CLI, or a one-off bootstrap
#      Terraform config that is applied once and then set aside) create:
#        - an S3 bucket for state storage, with versioning enabled and
#          public access blocked
#        - a DynamoDB table for state locking, with a partition key named
#          `LockID` (type String)
#   3. Uncomment the backend "s3" block below and fill in the bucket/table/
#      region values for the resources created in step 2.
#   4. Run `terraform init -migrate-state` to move the existing local state
#      into the new remote backend. Terraform will prompt for confirmation
#      before copying state.
#
# Backend configuration cannot use variables (var.*) — values must be
# literal or supplied via `-backend-config` at init time.
# ---------------------------------------------------------------------------

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE_WITH_STATE_BUCKET_NAME"
#     key            = "my-react-app/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "REPLACE_WITH_LOCK_TABLE_NAME"
#     encrypt        = true
#   }
# }
