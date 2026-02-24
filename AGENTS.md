# AGENTS.md

## Purpose

This file defines the working conventions for contributing to
[brickster](https://github.com/databrickslabs/brickster). The goal is
consistent API ergonomics, maintainable code, and tests that validate
behavior (not just coverage).

## Rule Strength

- **Must**: required for all new/modified code unless explicitly agreed
  otherwise in review.
- **Should**: strong default; deviate only with clear, documented
  rationale.

## Product Intent

[brickster](https://github.com/databrickslabs/brickster) is a pragmatic
R toolkit for Databricks: - thin, readable wrappers over Databricks REST
APIs - predictable function naming and return shapes - first-class auth
ergonomics (`PAT`, OAuth U2M, OAuth M2M) - practical workflows
(`DBI`/`dbplyr`, Unity Catalog volumes)

Prefer clear behavior over abstraction-heavy internals.

## Code Practices

### Function and file structure

- **Must** keep functions grouped by API domain in existing `R/*.R`
  files (clusters, jobs, volumes, auth, etc.).
- **Must** follow naming pattern: `db_<resource>_<action>`.
- **Should** add to an existing domain file before creating a new file.
- **Should** keep helper functions internal unless there is clear
  end-user value.

### Request wrapper pattern

- **Must** build requests via
  [`db_request()`](https://databrickslabs.github.io/brickster/reference/db_request.md).
- **Must** execute JSON API requests via
  [`db_perform_request()`](https://databrickslabs.github.io/brickster/reference/db_perform_request.md).
- **Should** execute non-JSON/binary/header requests via
  [`db_perform_response()`](https://databrickslabs.github.io/brickster/reference/db_perform_response.md)
  unless that helper clearly cannot support the endpoint.
- **Should** include in public API wrappers:
  - `host = db_host()`
  - `token = db_token()`
  - `perform_request = TRUE` when request inspection/testing is useful
- **Must** maintain stable return contracts:
  - `perform_request = FALSE` returns an `httr2_request`
  - action/delete endpoints default to `TRUE`/`FALSE`; return richer
    details only when meaningful endpoint data exists (for example:
    path/id/status details)
  - list/get endpoints should follow API response shape; return full
    bodies when pagination or metadata is needed and avoid dropping
    useful fields
  - explicitly document return shape differences in roxygen when
    endpoints in the same family differ

### Input validation and errors

- **Must** validate early.
- **Should** use
  [`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
  for user-facing argument errors when it can express the check clearly.
- **Should** use [`stopifnot()`](https://rdrr.io/r/base/stopifnot.html)
  for compact multi-condition assertions or internal invariants where it
  is clearer.
- **Must** make error messages actionable and specific (what is wrong,
  and how to fix).
- **Should** avoid hidden side effects and stateful behavior unless
  required.

### Style and dependencies

- **Must** use `TRUE`/`FALSE` over `T`/`F` in new code.
- **Must** use [fs](https://fs.r-lib.org) for path manipulation and
  filesystem checks.
- **Must** use [purrr](https://purrr.tidyverse.org/) for iteration in
  new/modified code (including tests); do not introduce new
  `*apply`/`vapply` iteration unless required for a specific external
  interface.
- **Should** keep comments sparse and only where behavior is
  non-obvious.

## Roxygen and Documentation

- **Must** use roxygen for all exported functions and run
  `devtools::document()` after API changes.
- **Must** include explicit `@returns` docs for every exported function,
  including `perform_request = TRUE` vs `FALSE` behavior when relevant.
- **Should** reuse parameter docs with `@inheritParams` (notably
  `auth_params` and shared request args).
- **Must** place functions in the correct `@family` for reference-site
  grouping.
- **Must** use [lifecycle](https://lifecycle.r-lib.org/) consistently
  for lifecycle changes:
  - add lifecycle badge in roxygen where relevant
  - emit deprecation warnings in each deprecated function (no hidden
    global helper if explicit per-function messaging is preferred)
- **Should** ensure new/changed public functions appear correctly in
  pkgdown reference structure (`_pkgdown.yml`) when needed.

## Test Strategy and Purpose

Tests are organized in three layers. Keep this structure.

### 1) Request-shape tests (`test-<domain>.R`)

- **Must** validate argument handling and request construction using
  `perform_request = FALSE`.
- **Must** check returned type (`httr2_request`) and key validation
  paths.

### 2) Offline helper tests (`test-<domain>-offline-helpers.R`)

- **Must** validate branching/business logic without network calls.
- **Must** use `local_mocked_bindings()` and assert behavior/output
  explicitly.

### 3) Integration tests (same domain test file as request-shape tests)

- **Must** guard real API tests with skip helpers (`skip_on_cran()`,
  auth/cloud guards).
- **Should** keep integration tests focused on key live behavior, not
  exhaustive API permutations.

### Test hygiene rules

- **Must** use
  [`withr::local_envvar()`](https://withr.r-lib.org/reference/with_envvar.html)
  /
  [`withr::local_options()`](https://withr.r-lib.org/reference/with_options.html)
  for temporary state.
- **Must not** use [`options()`](https://rdrr.io/r/base/options.html)
  directly in tests.
- **Must not** use
  [`Sys.unsetenv()`](https://rdrr.io/r/base/Sys.setenv.html) directly in
  tests.
- **Must not** use `brickster:::` in tests.
- **Must not** use `<<-`; track state with
  `new.env(parent = emptyenv())`.
- **Must** avoid nested mocking blocks.
- **Should** use at most one `local_mocked_bindings()` call per package
  within a single `test_that()` block; split phases into separate tests
  when needed.
- **Should** keep tests behavior-oriented; remove tests that only assert
  expected network failure with no additional value.

## Coverage Policy

- **Must** treat coverage as a signal, not the goal. Meaningful coverage
  is preferred over theater.
- **Should** treat ~80% project coverage as acceptable when critical
  paths are tested.
- **Must** prioritize tests for risk-bearing logic and user-visible
  behavior first.
- **Should** ignore coverage only when justified and hard to test
  (startup hooks, truly environment-specific branches, deprecated legacy
  code).
- **Must** use `.covrignore` or `# nocov start/end` sparingly and
  document rationale in PR notes.

## Change Process

### NEWS.md

- **Must** update `NEWS.md` for user-visible changes.
- **Must** use concise bullets with clear impact.
- **Should** use explicit references to function names in backticks.
- **Must** state replacement path and migration guidance for
  deprecations.

### Typical pre-PR checks

- `devtools::document()`
- [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html)
  (or targeted files while iterating)
- `covr::package_coverage(type = "tests")` when coverage impact is
  relevant

### PR checklist

Public behavior changes are documented in `NEWS.md`.

Roxygen docs are updated and regenerated.

Tests validate behavior changes (not just coverage lines).

Coverage exceptions (`.covrignore` / `# nocov`) are justified and
minimal.

## Adding a New Endpoint (Checklist)

Reference sources for endpoint work: - Databricks REST API docs:
<https://docs.databricks.com/api/workspace/introduction> - Databricks
Python SDK (repo): <https://github.com/databricks/databricks-sdk-py> -
Databricks Python SDK service implementations:
<https://github.com/databricks/databricks-sdk-py/tree/main/databricks/sdk/service>

1.  Confirm endpoint contract from Databricks docs (method, path,
    version, request/response shape), then compare behavior and naming
    against the Python SDK implementation when useful.
2.  Add wrapper(s) in correct domain file using existing naming and
    argument conventions.
3.  Add validation and predictable return shape.
4.  Add/extend request-shape tests (`perform_request = FALSE`).
5.  Add offline helper tests for non-trivial logic.
6.  Add/adjust integration tests only for high-value live behaviors.
7.  Update roxygen, run `devtools::document()`, verify `NAMESPACE`/`man`
    output.
8.  Update `NEWS.md` for user-visible behavior.
9.  Update vignette/README when workflow or recommended usage changes.

## API UX Principles

- Make common workflows obvious and short.
- Keep defaults safe and unsurprising.
- Prioritize consistent argument names across related functions.
- Prefer migration guidance over hard breaks.
