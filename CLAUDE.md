# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

A Create React App (react-scripts 5.0.1) single-page app. Deployed to AWS using S3 (static hosting) and CloudFront (CDN), provisioned with Terraform — not Docker/nginx.

## Files

- `src/App.js` — main app component/page
- `src/index.js` — React entry point
- `src/App.css`, `src/index.css` — styling (CRA defaults, not yet customized)
- `public/` — static assets and `index.html` shell
- `src/tests/App.test.js`, `src/App.test.js` — component tests (see test gotcha below)

### Infrastructure (`terraform/`)
- AWS S3 bucket for static site hosting (private, OAC-based access)
- CloudFront distribution as CDN with S3 origin
- GitHub OIDC provider + IAM role for keyless CI/CD auth
- Terraform state stored in S3 backend with DynamoDB locking
- All resources tagged with `Project` and `Environment`


## Commands

```bash
npm start              # dev server
npm run build           # production build (output: build/)
npm test                # run tests (see gotcha below)
```

## Gotchas

- `npm test` runs `react-scripts test tests` — the `tests` argument is a test-path pattern, so it only matches files under `src/tests/`. `src/App.test.js` at the top level is **not** run by default and must be targeted explicitly (`npm test -- App.test.js`).
- CI (`.github/workflows/ci-cd.yml`) runs `npm test -- --watch=false`, which inherits the same `tests` pattern restriction.


## MCP Servers (`.mcp.json`)

Two MCP servers are configured for Claude Code:
- **aws** (`awslabs.aws-api-mcp-server`) — Direct AWS API access for querying and managing resources
- **terraform** (`hashicorp/terraform-mcp-server`) — Terraform operations via Docker, workspace mounted at `/workspace`

AWS credentials and region are configured in `.claude/settings.local.json` (gitignored), not in `.mcp.json`. This keeps secrets out of version control and provides a single source of truth for all tools.

## Custom Agents (`.claude/agents/`)

This project has 4 specialized subagents. Use them by name when delegating tasks:
- **tf-writer** — generates Terraform code (has Write access + project memory)
- **security-auditor** — audits TF for security issues (Read-only, Sonnet)
- **cost-optimizer** — reviews infra cost (Read-only, Haiku)
- **drift-detector** — detects state drift (Bash, Haiku)

## Skills (`.claude/skills/`)

All infrastructure and deployment tasks are handled via skills. Do not write Terraform or CI/CD code manually — use the appropriate skill. Action skills have `disable-model-invocation: true` (manual only). The `project-scope` skill has `user-invocable: false` (auto-loaded by Claude as background knowledge).

/scaffold-terraform [region] [name]  → Generate all Terraform files (uses tf-writer agent)
/tf-plan                             → Run terraform plan + risk analysis
/tf-apply                            → Run terraform apply + verify
/deploy                              → Sync S3 + invalidate CloudFront
/infra-status                        → Health dashboard of all resources
/infra-audit                         → Parallel security + cost + drift audit (forked context)
/setup-gh-actions [create|validate]  → Create or validate CI workflow
/tf-destroy                          → Safe destroy with confirmation
project-scope                        → Background knowledge: AWS service constraints (auto-loaded)
/commit                              → Auto-generate commit message (built-in)
/compact                             → Compress long conversation context (built-in)

## Deployment

- Target: S3 (static hosting) + CloudFront (CDN), provisioned with Terraform. No Docker/nginx.
- `.github/workflows/ci-cd.yml` builds the app (`npm run build`), then on push to `main` only (not on PRs) authenticates to AWS via GitHub OIDC (no stored access keys), syncs `build/` to S3, and invalidates the CloudFront cache.
- Requires these set in the repo's GitHub settings before the deploy steps will work:
  - Secret `AWS_ROLE_ARN` — IAM role the workflow assumes via OIDC (trust policy must allow this repo).
  - Variables `AWS_REGION`, `S3_BUCKET_NAME`, `CLOUDFRONT_DISTRIBUTION_ID`.
  
  ## Commands

```bash
# Terraform
cd terraform && terraform init
cd terraform && terraform plan
cd terraform && terraform apply


# Local preview
npm start

## Build before S3 sync
npm run build

# Manual S3 sync (CI does this automatically)
aws s3 sync build/ s3://$BUCKET_NAME --exclude "terraform/*" --exclude ".git/*" --exclude ".github/*" --exclude "*.md" --exclude ".claude/*"
```

## Safety Layers
1. **UserPromptSubmit hook** — catches destructive intent ("delete all", "nuke", "wipe") before Claude starts
2. **PreToolUse hook** — blocks dangerous commands (terraform destroy, aws s3 rm) at execution time
3. **Permissions** — auto-allows safe reads, blocks IAM and rm -rf
4. **PostToolUse hook** — logs all terraform apply executions to `.claude/deploy.log`

## Conventions
- Terraform files use `terraform/` directory with standard layout (main.tf, variables.tf, outputs.tf)
- GitHub Actions uses OIDC — no stored AWS access keys
- All infrastructure changes go through Terraform — never modify AWS resources manually
- Site content changes deploy automatically via GitHub Actions on push to main

## Mandatory ownership-proof rule

Per README.md, before deployment `src/App.js` must be edited to add student/cohort identification (currently placeholder text: `Deployed by: Your Full Name` and `Date: DD/MM/YYYY`). Don't remove or "clean up" these lines without the user's explicit direction — it's a graded requirement, not leftover content.
