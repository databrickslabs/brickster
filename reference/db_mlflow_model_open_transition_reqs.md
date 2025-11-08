# Get All Open Stage Transition Requests for the Model Version

Get All Open Stage Transition Requests for the Model Version

## Usage

``` r
db_mlflow_model_open_transition_reqs(
  name,
  version,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- name:

  Name of the model.

- version:

  Version of the model.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## See also

Other Model Registry API:
[`db_mlflow_model_approve_transition_req()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_approve_transition_req.md),
[`db_mlflow_model_delete_transition_req()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_delete_transition_req.md),
[`db_mlflow_model_reject_transition_req()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_reject_transition_req.md),
[`db_mlflow_model_transition_req()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_transition_req.md),
[`db_mlflow_model_transition_stage()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_transition_stage.md),
[`db_mlflow_model_version_comment()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_version_comment.md),
[`db_mlflow_model_version_comment_delete()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_version_comment_delete.md),
[`db_mlflow_model_version_comment_edit()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_model_version_comment_edit.md),
[`db_mlflow_registered_model_details()`](https://databrickslabs.github.io/brickster/reference/db_mlflow_registered_model_details.md)
