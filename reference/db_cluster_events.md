# List Cluster Activity Events

List Cluster Activity Events

## Usage

``` r
db_cluster_events(
  cluster_id,
  start_time = NULL,
  end_time = NULL,
  event_types = NULL,
  order = c("DESC", "ASC"),
  offset = 0,
  limit = 50,
  host = db_host(),
  token = db_token(),
  perform_request = TRUE
)
```

## Arguments

- cluster_id:

  The ID of the cluster to retrieve events about.

- start_time:

  The start time in epoch milliseconds. If empty, returns events
  starting from the beginning of time.

- end_time:

  The end time in epoch milliseconds. If empty, returns events up to the
  current time.

- event_types:

  List. Optional set of event types to filter by. Default is to return
  all events. [Event
  Types](https://docs.databricks.com/api/workspace/clusters/events#events).

- order:

  Either `DESC` (default) or `ASC`.

- offset:

  The offset in the result set. Defaults to 0 (no offset). When an
  offset is specified and the results are requested in descending order,
  the end_time field is required.

- limit:

  Maximum number of events to include in a page of events. Defaults to
  50, and maximum allowed value is 500.

- host:

  Databricks workspace URL, defaults to calling
  [`db_host()`](https://databrickslabs.github.io/brickster/reference/db_host.md).

- token:

  Databricks workspace token, defaults to calling
  [`db_token()`](https://databrickslabs.github.io/brickster/reference/db_token.md).

- perform_request:

  If `TRUE` (default) the request is performed, if `FALSE` the httr2
  request is returned *without* being performed.

## Details

Retrieve a list of events about the activity of a cluster. You can
retrieve events from active clusters (running, pending, or
reconfiguring) and terminated clusters within 30 days of their last
termination. This API is paginated. If there are more events to read,
the response includes all the parameters necessary to request the next
page of events.

## See also

Other Clusters API:
[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md),
[`db_cluster_get()`](https://databrickslabs.github.io/brickster/reference/db_cluster_get.md),
[`db_cluster_list()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list.md),
[`db_cluster_list_node_types()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_node_types.md),
[`db_cluster_list_zones()`](https://databrickslabs.github.io/brickster/reference/db_cluster_list_zones.md),
[`db_cluster_perm_delete()`](https://databrickslabs.github.io/brickster/reference/db_cluster_perm_delete.md),
[`db_cluster_pin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_pin.md),
[`db_cluster_resize()`](https://databrickslabs.github.io/brickster/reference/db_cluster_resize.md),
[`db_cluster_restart()`](https://databrickslabs.github.io/brickster/reference/db_cluster_restart.md),
[`db_cluster_runtime_versions()`](https://databrickslabs.github.io/brickster/reference/db_cluster_runtime_versions.md),
[`db_cluster_start()`](https://databrickslabs.github.io/brickster/reference/db_cluster_start.md),
[`db_cluster_terminate()`](https://databrickslabs.github.io/brickster/reference/db_cluster_terminate.md),
[`db_cluster_unpin()`](https://databrickslabs.github.io/brickster/reference/db_cluster_unpin.md),
[`get_and_start_cluster()`](https://databrickslabs.github.io/brickster/reference/get_and_start_cluster.md),
[`get_latest_dbr()`](https://databrickslabs.github.io/brickster/reference/get_latest_dbr.md)
