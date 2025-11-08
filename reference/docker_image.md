# Docker Image

Docker image connection information.

## Usage

``` r
docker_image(url, username, password)
```

## Arguments

- url:

  URL for the Docker image.

- username:

  User name for the Docker repository.

- password:

  Password for the Docker repository.

## Details

Uses basic authentication, **strongly** recommended that credentials are
not stored in any scripts and environment variables should be used.

## See also

[`db_cluster_create()`](https://databrickslabs.github.io/brickster/reference/db_cluster_create.md),
[`db_cluster_edit()`](https://databrickslabs.github.io/brickster/reference/db_cluster_edit.md)
