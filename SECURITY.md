# Security Runbook

## GitHub Actions Runtime Environment

Workflows that run package code with Databricks runtime secrets must declare the
`runtime` GitHub Actions environment. The repository settings for that
environment must enforce required reviewers before internal GitHub Actions
runners are enabled.

Required configuration:

- Environment name: `runtime`
- Protection rule: required reviewers enabled
- Reviewers: security owners or trusted maintainers for this repository
- Self-review prevention: enabled when available

This protects fork pull request runs by requiring an approved environment
deployment before jobs can access `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, or other
runtime secrets.

Before enabling or changing internal runners, verify the environment still has
required reviewers configured in GitHub repository settings under
`Settings > Environments > runtime`.

## Pull Request Comment Commands

The `/document` and `/style` issue-comment commands fetch the pull request branch
and execute R code from that branch. For external contributor pull requests,
members and owners must review the PR's R code for malicious constructs before
triggering either command.
