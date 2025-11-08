# Git Source for Job Notebook Tasks

Git Source for Job Notebook Tasks

## Usage

``` r
git_source(
  git_url,
  git_provider,
  reference,
  type = c("branch", "tag", "commit")
)
```

## Arguments

- git_url:

  URL of the repository to be cloned by this job. The maximum length is
  300 characters.

- git_provider:

  Unique identifier of the service used to host the Git repository. Must
  be one of: `github`, `bitbucketcloud`, `azuredevopsservices`,
  `githubenterprise`, `bitbucketserver`, `gitlab`,
  `gitlabenterpriseedition`, `awscodecommit`.

- reference:

  Branch, tag, or commit to be checked out and used by this job.

- type:

  Type of reference being used, one of: `branch`, `tag`, `commit`.
