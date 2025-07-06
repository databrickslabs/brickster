#' dbplyr Backend for Databricks SQL
#'
#' @description
#' This file implements dbplyr backend support for Databricks SQL warehouses,
#' enabling dplyr syntax to be translated to Databricks SQL.
#'
#' @importFrom dbplyr sql_variant sql_translator base_scalar base_agg base_win
#' @importFrom dbplyr sql_prefix sql sql_table_analyze sql_quote sql_query_fields
#' @importFrom dbplyr translate_sql dbplyr_edition sql_query_save
#' @importFrom glue glue_sql
#' @importFrom DBI SQL
#' @importFrom methods setMethod
#' @name databricks-dbplyr
NULL

# Backend Registration ----------------------------------------------------------

#' Declare dbplyr API version for Databricks connections
#' @param con A DatabricksConnection object
#' @return The dbplyr edition number (2L)
#' @export
#' @method dbplyr_edition DatabricksConnection
dbplyr_edition.DatabricksConnection <- function(con) {
  2L
}

# SQL Translation Environment ---------------------------------------------------

#' SQL translation environment for Databricks SQL
#' @keywords internal
sql_translate_env.DatabricksConnection <- function(con) {
  list(
    # Scalar function translations
    scalar = dbplyr::sql_translator(
      .parent = dbplyr::base_scalar,
      # String concatenation - Databricks supports concat()
      paste = dbplyr::sql_prefix("concat"),
      paste0 = dbplyr::sql_prefix("concat"),
      str_c = dbplyr::sql_prefix("concat"),

      # String functions
      str_length = dbplyr::sql_prefix("length"),
      nchar = dbplyr::sql_prefix("length"),
      str_to_upper = dbplyr::sql_prefix("upper"),
      str_to_lower = dbplyr::sql_prefix("lower"),
      str_trim = dbplyr::sql_prefix("trim"),
      str_ltrim = dbplyr::sql_prefix("ltrim"),
      str_rtrim = dbplyr::sql_prefix("rtrim"),
      substr = dbplyr::sql_prefix("substring"),
      str_sub = dbplyr::sql_prefix("substring"),

      # Date/time functions - Databricks specific
      today = function() dbplyr::sql("current_date()"),
      now = function() dbplyr::sql("current_timestamp()"),
      Sys.Date = function() dbplyr::sql("current_date()"),
      Sys.time = function() dbplyr::sql("current_timestamp()"),

      # Math functions
      round = dbplyr::sql_prefix("round"),
      ceiling = dbplyr::sql_prefix("ceil"),
      floor = dbplyr::sql_prefix("floor"),
      abs = dbplyr::sql_prefix("abs"),
      sqrt = dbplyr::sql_prefix("sqrt"),

      # Logical functions
      is.null = dbplyr::sql_prefix("isnull"),
      is.na = dbplyr::sql_prefix("isnull"),

      # Type conversion
      as.character = dbplyr::sql_prefix("cast", "string"),
      as.numeric = dbplyr::sql_prefix("cast", "double"),
      as.integer = dbplyr::sql_prefix("cast", "int")
    ),

    # Aggregation function translations
    aggregate = dbplyr::sql_translator(
      .parent = dbplyr::base_agg,
      n = function() dbplyr::sql("count(*)"),
      n_distinct = function(x) dbplyr::sql(paste0("count(distinct ", x, ")")),

      # Statistical functions
      mean = dbplyr::sql_prefix("avg"),
      sd = dbplyr::sql_prefix("stddev"),
      var = dbplyr::sql_prefix("variance"),
      median = dbplyr::sql_prefix("percentile", "0.5")
    ),

    # Window function translations
    window = dbplyr::sql_translator(
      .parent = dbplyr::base_win,
      # Databricks supports standard window functions
      row_number = dbplyr::sql_prefix("row_number"),
      rank = dbplyr::sql_prefix("rank"),
      dense_rank = dbplyr::sql_prefix("dense_rank"),
      lag = dbplyr::sql_prefix("lag"),
      lead = dbplyr::sql_prefix("lead"),
      first_value = dbplyr::sql_prefix("first_value"),
      last_value = dbplyr::sql_prefix("last_value")
    )
  )
}


# Database-Specific SQL Methods -------------------------------------------------

#' Handle table analysis for Databricks
#' @param con A DatabricksConnection object
#' @param table Table name to analyze
#' @param ... Additional arguments (ignored)
#' @return SQL statement for table analysis
#' @export
#' @method sql_table_analyze DatabricksConnection
sql_table_analyze.DatabricksConnection <- function(con, table, ...) {
  glue::glue_sql("ANALYZE TABLE {`table`} COMPUTE STATISTICS", .con = con)
}


# Simple approach: Override dbQuoteIdentifier to use backticks for Databricks
# This follows the DBI standard and uses S4 methods like other DBI backends

#' Quote identifiers for Databricks SQL
#' @param conn A DatabricksConnection object
#' @param x Character vector of identifiers to quote
#' @param ... Additional arguments (ignored)
#' @return SQL object with quoted identifiers
#' @export
setMethod(
  "dbQuoteIdentifier",
  signature("DatabricksConnection", "character"),
  function(conn, x, ...) {
    # Simple identifiers - wrap in backticks
    quoted <- paste0("`", x, "`")
    DBI::SQL(quoted)
  }
)

#' Quote SQL objects (passthrough)
#' @param conn A DatabricksConnection object
#' @param x SQL object (already quoted)
#' @param ... Additional arguments (ignored)
#' @return The SQL object unchanged
#' @export
setMethod(
  "dbQuoteIdentifier",
  signature("DatabricksConnection", "SQL"),
  function(conn, x, ...) {
    # SQL objects are already quoted
    x
  }
)

#' Quote complex identifiers (schema.table)
#' @param conn A DatabricksConnection object
#' @param x Id object with catalog/schema/table components
#' @param ... Additional arguments (ignored)
#' @return SQL object with quoted identifier components
#' @export
setMethod(
  "dbQuoteIdentifier",
  signature("DatabricksConnection", "Id"),
  function(conn, x, ...) {
    # Handle schema.table identifiers
    names <- purrr::map_chr(x@name, function(y) paste0("`", y, "`"))
    DBI::SQL(paste(names, collapse = "."))
  }
)

# Table Operations ---------------------------------------------------------------

#' Handle temporary table creation (not supported in read-only mode)
#' @param con A DatabricksConnection object
#' @param sql SQL query to save as table
#' @param name Name for the temporary table
#' @param temporary Whether the table should be temporary
#' @param ... Additional arguments (ignored)
#' @return Always throws an error (read-only connection)
#' @export
#' @method sql_query_save DatabricksConnection
sql_query_save.DatabricksConnection <- function(
  con,
  sql,
  name,
  temporary = TRUE,
  ...
) {
  cli::cli_abort(
    "Temporary table creation is not supported in read-only mode. Use collect() to retrieve results."
  )
}

# Query Field Discovery ---------------------------------------------------------

#' SQL Query Fields for Databricks connections
#' @description
#' Generate SQL for field discovery queries optimized for Databricks.
#' This method generates appropriate SQL for discovering table fields.
#' @param con DatabricksConnection object
#' @param sql SQL query to discover fields for
#' @param ... Additional arguments passed to other methods
#' @return SQL object for field discovery
#' @export
#' @method sql_query_fields DatabricksConnection
sql_query_fields.DatabricksConnection <- function(con, sql, ...) {
  # Use the default dbplyr implementation
  NextMethod()
}

# Package Loading Hook ----------------------------------------------------------

#' @keywords internal
.onLoad <- function(libname, pkgname) {
  # Register S3 method for sql_translate_env if dbplyr is available
  if (requireNamespace("dbplyr", quietly = TRUE)) {
    s3_register("dbplyr::sql_translate_env", "DatabricksConnection")
  }
}

#' Register S3 method helper
#' @keywords internal
s3_register <- function(generic, class, method = NULL) {
  stopifnot(is.character(generic), length(generic) == 1)
  stopifnot(is.character(class), length(class) == 1)

  pieces <- strsplit(generic, "::")[[1]]
  stopifnot(length(pieces) == 2)
  package <- pieces[[1]]
  generic <- pieces[[2]]

  caller <- parent.frame()

  get_method_env <- function() {
    top <- topenv(caller)
    if (isNamespace(top)) {
      asNamespace(environmentName(top))
    } else {
      caller
    }
  }
  get_method <- function(method, env) {
    if (is.null(method)) {
      get(paste0(generic, ".", class), env)
    } else {
      method
    }
  }

  method_fn <- get_method(method, get_method_env())
  stopifnot(is.function(method_fn))

  # Always register hook in case package is unloaded then reloaded
  setHook(
    packageEvent(package, "onLoad"),
    function(...) {
      ns <- asNamespace(package)

      # Refresh the method, it might have been dirtied by competing packages
      method_fn <- get_method(method, get_method_env())

      registerS3method(generic, class, method_fn, envir = ns)
    }
  )

  # Avoid registration failures during loading (pkgload or regular)
  if (!isNamespaceLoaded(package)) {
    return(invisible())
  }

  envir <- asNamespace(package)

  # Only register if generic can be accessed
  if (exists(generic, envir)) {
    registerS3method(generic, class, method_fn, envir = envir)
  }
}
