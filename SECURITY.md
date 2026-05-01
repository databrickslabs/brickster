# Security Runbook

## GitHub Actions Runtime Environment

Default pull request checks must run without Databricks runtime secrets. Pull
request jobs may run package code with `DATABRICKS_HOST`, `DATABRICKS_TOKEN`,
`DATABRICKS_WSID`, or other runtime secrets only when they declare the `runtime`
environment and an environment reviewer approves the run.

Trusted workflows that run package code with Databricks runtime secrets must
declare the `runtime` GitHub Actions environment. The repository settings for
that environment must enforce required reviewers before runtime secrets or
internal GitHub Actions runners are enabled.

Required configuration:

- Environment name: `runtime`
- Protection rule: required reviewers enabled
- Reviewers: security owners or trusted maintainers for this repository
- Self-review prevention: enabled when available

This keeps default fork and pull request checks outside the Databricks trust
boundary. Runtime jobs may execute repository code with `DATABRICKS_HOST`,
`DATABRICKS_TOKEN`, or other runtime secrets only after the environment gate has
been approved.

Before enabling or changing internal runners, verify the environment still has
required reviewers configured in GitHub repository settings under
`Settings > Environments > runtime`.

## Pull Request Comment Commands

The `/document` and `/style` issue-comment commands fetch the pull request branch
and execute R code from that branch. These workflows must stay artifact-only:

- run only on GitHub-hosted runners;
- use only read-only repository permissions;
- never declare the `runtime` environment;
- never receive Databricks runtime secrets;
- never push directly to the pull request branch.

Members and owners may use the generated patch artifact after reviewing it. Do
not restore an auto-push command unless it is limited to same-repository PR
branches after validating the PR head repository through the GitHub API.

## Branch Protection

The default branch must require pull request review and status checks before
merge. Required configuration:

- Require at least one approving review.
- Require CODEOWNERS review for `.github/workflows/`, `.github/actions/`, and
  `.github/CODEOWNERS`.
- Require CI status checks that cover R CMD check and coverage before merge:
  `R-CMD-check-pr-required` and `test-coverage-pr-required`.
- Dismiss stale reviews or require approval of the latest pushed commit.
- Restrict who can bypass required pull requests and status checks.
