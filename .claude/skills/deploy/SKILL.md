---
name: deploy
description: build and sync site files to S3 and invalidate CloudFront cache. Use after terraform apply to push site content live.
allowed-tools: Bash, Read
disable-model-invocation: true
---

Deploy site files to S3 and invalidate CloudFront cache.

Steps:
- [ ] Get terraform outputs: `cd terraform && terraform output -json`
- [ ] Install dependencies and run npm build before syncing files to S3: `npm ci && npm run build`
- [ ] Sync site files: `aws s3 sync build/ s3://<bucket> --exclude "terraform/*" --exclude ".git/*" --exclude ".github/*" --exclude "*.md" --exclude ".claude/*" --exclude ".cursor/*" --exclude ".mcp.json" --delete`
- [ ] Invalidate cache: `aws cloudfront create-invalidation --distribution-id <dist-id> --paths "/*"`
- [ ] Report the CloudFront URL and invalidation status

If any step fails, stop and report the error. Do not continue to the next step.
