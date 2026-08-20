---
name: repo-identity
description: The GitHub org/repo this project's OIDC trust policy should be scoped to — use to validate terraform/github-oidc.tf's sub claim condition hasn't drifted.
metadata:
  type: reference
---

The git remote `origin` for this project is `https://github.com/ByronTechCoder/my-react-app.git`.

The OIDC trust policy in `terraform/github-oidc.tf` should scope its `sub` claim condition to
`repo:ByronTechCoder/my-react-app:ref:refs/heads/main` (or more branches if the deploy
workflow is later triggered from other branches). If a future audit finds a different
org/repo string in that condition, treat it as a HIGH finding (wrong-repo scoping is
either a functional bug or, if too broad, a privilege-escalation risk) — confirm
against `git config --get remote.origin.url` rather than trusting this memory blindly,
since the repo could be renamed or transferred.
