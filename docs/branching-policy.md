# Branching Policy

This repository follows a trunk-based workflow for infrastructure changes.

## Rules

1. All changes are merged into `main` through pull requests.
2. Direct commits to `main` are prohibited.
3. Short-lived feature branches are allowed for isolated work.
4. Production changes require validation, sign-off, and approval.
5. Stage and production promotions must pass security and compliance checks.

## Recommended flow

```bash
git checkout -b feature/my-change
git push origin feature/my-change
# open PR to main
# validate with pipeline
# approve and merge
```

## Pipeline protection

The repository should enforce the following branch protections in Azure DevOps:

- require PRs before merging to `main`
- require status checks to pass
- require at least one reviewer
- prevent direct pushes to protected branches
- require branch deletion after merge
