# Access Control Request For User

Access Control Request For User

## Usage

``` r
access_control_req_user(
  user_name,
  permission_level = c("CAN_MANAGE", "CAN_MANAGE_RUN", "CAN_VIEW", "IS_OWNER")
)
```

## Arguments

- user_name:

  Email address for the user.

- permission_level:

  Permission level to grant. One of `CAN_MANAGE`, `CAN_MANAGE_RUN`,
  `CAN_VIEW`, `IS_OWNER`.

## See also

[`access_control_request()`](https://databrickslabs.github.io/brickster/reference/access_control_request.md)

Other Access Control Request Objects:
[`access_control_req_group()`](https://databrickslabs.github.io/brickster/reference/access_control_req_group.md)
