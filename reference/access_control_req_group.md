# Access Control Request for Group

Access Control Request for Group

## Usage

``` r
access_control_req_group(
  group,
  permission_level = c("CAN_MANAGE", "CAN_MANAGE_RUN", "CAN_VIEW")
)
```

## Arguments

- group:

  Group name. There are two built-in groups: `users` for all users, and
  `admins` for administrators.

- permission_level:

  Permission level to grant. One of `CAN_MANAGE`, `CAN_MANAGE_RUN`,
  `CAN_VIEW`.

## See also

[`access_control_request()`](https://databrickslabs.github.io/brickster/reference/access_control_request.md)

Other Access Control Request Objects:
[`access_control_req_user()`](https://databrickslabs.github.io/brickster/reference/access_control_req_user.md)
