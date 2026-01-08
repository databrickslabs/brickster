#' dbplyr Backend for Databricks SQL
#'
#' @description
#' This file implements dbplyr backend support for Databricks SQL warehouses,
#' enabling dplyr syntax to be translated to Databricks SQL.
#'
#' @importFrom dbplyr sql_variant sql_translator base_scalar base_agg base_win
#' @importFrom dbplyr sql_prefix sql sql_table_analyze sql_quote sql_query_fields
#' @importFrom dbplyr translate_sql dbplyr_edition sql_query_save simulate_spark_sql db_collect
#' @importFrom dplyr copy_to
#' @importFrom glue glue_sql
#' @importFrom purrr map_chr map2_chr
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
#' @importFrom dbplyr sql_translation
#' @export
#' @method sql_translation DatabricksConnection
sql_translation.DatabricksConnection <- function(con) {
  spark_sql_translation(con)
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


# Table Operations ---------------------------------------------------------------

#' Generate unique temporary table/view name
#' @param prefix Base name prefix (default: "dbplyr_temp")
#' @return Unique temporary name
#' @keywords internal
generate_temp_name <- function(prefix = "dbplyr_temp") {
  paste0(
    prefix, "_", 
    format(Sys.time(), "%Y%m%d_%H%M%S"), "_", 
    sample(10000:99999, 1)
  )
}


#' Create temporary views and tables in Databricks
#' @param con A DatabricksConnection object
#' @param sql SQL query to save as table/view
#' @param name Name for the temporary view or table
#' @param temporary Whether the object should be temporary (default: TRUE)
#' @param ... Additional arguments (ignored)
#' @return The table/view name (invisibly)
#' @export
#' @method sql_query_save DatabricksConnection
sql_query_save.DatabricksConnection <- function(
  con,
  sql,
  name,
  temporary = TRUE,
  ...
) {
  # Validate inputs
  if (!DBI::dbIsValid(con)) {
    cli::cli_abort("Connection is not valid")
  }
  
  if (missing(name) || is.null(name) || !nzchar(trimws(name))) {
    cli::cli_abort("Table/view name must be provided and non-empty")
  }
  
  if (missing(sql) || is.null(sql) || !nzchar(trimws(as.character(sql)))) {
    cli::cli_abort("SQL query must be provided and non-empty")
  }
  
  # For user-provided names, ensure uniqueness to avoid conflicts
  # Don't modify dbplyr-generated names (they start with dbplyr_)
  if (temporary && is.character(name) && !grepl("^dbplyr_", name) && nzchar(trimws(name))) {
    name <- generate_temp_name(name)
  }
  
  # Create appropriate SQL based on temporary flag
  if (temporary) {
    # Use TEMPORARY VIEW for session-scoped objects
    if (is.character(name) && grepl("^`.*`$", name)) {
      quoted_name <- name  # Already quoted
    } else {
      quoted_name <- DBI::dbQuoteIdentifier(con, name)
    }
    create_sql <- paste0(
      "CREATE OR REPLACE TEMPORARY VIEW ", 
      quoted_name, 
      " AS ", 
      as.character(sql)
    )
  } else {
    # Use regular table for persistent objects
    if (is.character(name) && grepl("^`.*`$", name)) {
      quoted_name <- name  # Already quoted
    } else {
      quoted_name <- DBI::dbQuoteIdentifier(con, name)
    }
    create_sql <- paste0(
      "CREATE OR REPLACE TABLE ", 
      quoted_name, 
      " AS ", 
      as.character(sql)
    )
  }
  
  # Execute the creation SQL
  DBI::dbExecute(con, create_sql)
  
  invisible(name)
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
  # Instead of using WHERE (0 = 1), use LIMIT 0 which is more efficient in Databricks
  result <- paste0("SELECT * FROM (", sql, ") LIMIT 0")
  dbplyr::sql(result)
}





#' Copy data frame to Databricks as table or view
#' @param dest A DatabricksConnection object
#' @param df Data frame to copy
#' @param name Name for the table/view
#' @param overwrite Whether to overwrite existing table/view
#' @param temporary Whether to create as temporary view (default: TRUE, but NOT SUPPORTED - will error)
#' @param ... Additional arguments passed to dbWriteTable
#' @return dbplyr table reference
#' @details Note: temporary=TRUE will result in an error as temporary tables are not
#'   supported with the SQL Statement Execution API. Use temporary=FALSE to create regular tables.
#' @export
#' @method copy_to DatabricksConnection
copy_to.DatabricksConnection <- function(
  dest,
  df,
  name = deparse(substitute(df)),
  overwrite = FALSE,
  temporary = TRUE,
  ...
) {
  # Validate inputs
  if (!DBI::dbIsValid(dest)) {
    cli::cli_abort("Connection is not valid")
  }
  
  if (!is.data.frame(df)) {
    cli::cli_abort("df must be a data frame")
  }
  
  # Note: sql_query_save will handle name generation for temporary objects
  
  if (temporary) {
    # For temporary views, try using dbWriteTable with temporary=TRUE
    # This should work better with SEA than the VALUES approach
    if (nrow(df) == 0) {
      cli::cli_abort("Cannot copy empty data frame")
    }
    
    # Use dbWriteTable with temporary=TRUE - let DBI handle the implementation
    DBI::dbWriteTable(
      dest, 
      name, 
      df, 
      overwrite = overwrite, 
      temporary = TRUE,  # Let DBI handle temporary table creation
      ...
    )
    final_name <- name
    
  } else {
    # For persistent tables, use dbWriteTable directly
    DBI::dbWriteTable(
      dest, 
      name, 
      df, 
      overwrite = overwrite, 
      temporary = FALSE,
      ...
    )
    final_name <- name
  }
  
  # Return dbplyr table reference
  dplyr::tbl(dest, final_name)
}

#' Generate typed VALUES SQL for temporary views (helper)
#' @param con DatabricksConnection object
#' @param data Data frame
#' @return SQL VALUES clause
#' @keywords internal
db_generate_typed_values_sql_for_view <- function(con, data) {
  # Convert each row to SQL values with proper typing
  row_values <- apply(data, 1, function(row) {
    values <- purrr::map2_chr(row, names(data), function(val, col_name) {
      col_data <- data[[col_name]]
      
      if (is.na(val)) {
        "NULL"
      } else if (is.logical(col_data)) {
        if (as.logical(val)) "TRUE" else "FALSE"
      } else if (is.numeric(col_data)) {
        # Don't quote numeric values to preserve type
        as.character(val)
      } else if (is.character(col_data)) {
        # Quote string values and escape single quotes
        db_escape_string_literal(con, val)
      } else {
        # Default to quoted string for other types
        db_escape_string_literal(con, as.character(val))
      }
    })
    paste0("(", paste(values, collapse = ", "), ")")
  })
  
  paste(row_values, collapse = ", ")
}

# Slightly modified version of sparklyr/R/dplyr_sql_translation.R (thank you!)
#' @importFrom dbplyr build_sql
#' @importFrom dbplyr win_over
#' @importFrom dbplyr sql
#' @importFrom dbplyr win_current_group
#' @importFrom dbplyr win_current_order
#' @importFrom rlang %||%
spark_sql_translation <- function(con) {
  win_recycled_params <- function(prefix) {
    function(x, y) {
      # Use win_current_frame() once exported form `dbplyr`
      sql_context <- get("sql_context", envir = asNamespace("dbplyr"))
      frame <- sql_context$frame

      dbplyr::win_over(
        dbplyr::build_sql(dbplyr::sql(prefix), "(", x, ",", y, ")"),
        partition = dbplyr::win_current_group(),
        order = if (!is.null(frame)) dbplyr::win_current_order(),
        frame = frame
      )
    }
  }
  sql_if_else <- function(cond, if_true, if_false, if_missing = NULL) {
    dbplyr::build_sql(
      "IF(ISNULL(",
      cond,
      "), ",
      if_missing %||% dbplyr::sql("NULL"),
      ", IF(",
      cond %||% dbplyr::sql("NULL"),
      ", ",
      if_true %||% dbplyr::sql("NULL"),
      ", ",
      if_false %||% dbplyr::sql("NULL"),
      "))"
    )
  }

  weighted_mean_sql <- function(x, w) {
    x <- dbplyr::build_sql(x)
    w <- dbplyr::build_sql(w)
    dbplyr::sql(
      paste(
        "CAST(SUM(IF(ISNULL(",
        w,
        "), 0, ",
        w,
        ") * IF(ISNULL(",
        x,
        "), 0, ",
        x,
        ")) AS DOUBLE)",
        "/",
        "CAST(SUM(IF(ISNULL(",
        w,
        "), 0, ",
        w,
        ") * IF(ISNULL(",
        x,
        "), 0, 1)) AS DOUBLE)"
      )
    )
  }

  spark_base_sql_variant <- list(
    scalar = dbplyr::sql_translator(
      .parent = dbplyr::base_scalar,
      as.numeric = function(x) dbplyr::build_sql("CAST(", x, " AS DOUBLE)"),
      as.double = function(x) dbplyr::build_sql("CAST(", x, " AS DOUBLE)"),
      as.integer = function(x) dbplyr::build_sql("CAST(", x, " AS INT)"),
      as.logical = function(x) dbplyr::build_sql("CAST(", x, " AS BOOLEAN)"),
      as.character = function(x) dbplyr::build_sql("CAST(", x, " AS STRING)"),
      as.date = function(x) dbplyr::build_sql("CAST(", x, " AS DATE)"),
      as.Date = function(x) dbplyr::build_sql("CAST(", x, " AS DATE)"),
      paste = function(..., sep = " ") {
        dbplyr::build_sql("CONCAT_WS", list(sep, ...))
      },
      paste0 = function(...) dbplyr::build_sql("CONCAT", list(...)),
      xor = function(x, y) dbplyr::build_sql(x, " ^ ", y),
      or = function(x, y) dbplyr::build_sql(x, " OR ", y),
      and = function(x, y) dbplyr::build_sql(x, " AND ", y),
      `%like%` = function(x, y) dbplyr::build_sql(x, " LIKE ", y),
      `%rlike%` = function(x, y) dbplyr::build_sql(x, " RLIKE ", y),
      `%regexp%` = function(x, y) dbplyr::build_sql(x, " REGEXP ", y),
      ifelse = sql_if_else,
      if_else = sql_if_else,
      grepl = function(x, y) dbplyr::build_sql(y, " RLIKE ", x),
      rowSums = function(x, na.rm = FALSE) {
        x <- rlang::enexpr(x)
        x <- rlang::eval_tidy(x)
        if (!"tbl_spark" %in% class(x)) {
          "unsupported subsetting expression"
        }
        col_names <- x |> colnames()

        if (length(col_names) == 0) {
          dbplyr::sql("0")
        } else {
          as_summand <- function(column) {
            if (!na.rm) {
              list(dbplyr::ident(column))
            } else {
              list(
                dbplyr::sql("IF(ISNULL("),
                dbplyr::ident(column),
                dbplyr::sql("), 0, "),
                dbplyr::ident(column),
                dbplyr::sql(")")
              )
            }
          }
          sum_expr <- list(dbplyr::sql("(")) |>
            append(
              lapply(
                col_names[-length(col_names)],
                function(x) {
                  append(as_summand(x), list(dbplyr::sql(" + ")))
                }
              ) |>
                unlist(recursive = FALSE)
            ) |>
            append(
              as_summand(col_names[[length(col_names)]])
            ) |>
            append(list(dbplyr::sql(")"))) |>
            lapply(function(x) dbplyr::escape(x, con = con))
          args <- append(sum_expr, list(con = con))

          do.call(dbplyr::build_sql, args)
        }
      },

      # Lubridate date/time functions
      year = function(x) dbplyr::build_sql("YEAR(", x, ")"),
      month = function(x) dbplyr::build_sql("MONTH(", x, ")"),
      day = function(x) dbplyr::build_sql("DAY(", x, ")"),
      mday = function(x) dbplyr::build_sql("DAY(", x, ")"),
      yday = function(x) dbplyr::build_sql("DAYOFYEAR(", x, ")"),
      wday = function(x, label = FALSE, abbr = TRUE, week_start = 1) {
        if (label) {
          if (abbr) {
            dbplyr::build_sql("DATE_FORMAT(", x, ", 'E')")
          } else {
            dbplyr::build_sql("DATE_FORMAT(", x, ", 'EEEE')")
          }
        } else {
          # Databricks WEEKDAY: 0=Monday, 1=Tuesday, ..., 6=Sunday
          # Databricks DAYOFWEEK: 1=Sunday, 2=Monday, ..., 7=Saturday
          # lubridate wday: 1=Sunday, 2=Monday, ..., 7=Saturday (default)
          # Use DAYOFWEEK which matches lubridate's default behavior
          dbplyr::build_sql("DAYOFWEEK(", x, ")")
        }
      },
      week = function(x) dbplyr::build_sql("WEEKOFYEAR(", x, ")"),
      weekday = function(x) dbplyr::build_sql("WEEKDAY(", x, ")"),
      quarter = function(x) dbplyr::build_sql("QUARTER(", x, ")"),
      hour = function(x) dbplyr::build_sql("HOUR(", x, ")"),
      minute = function(x) dbplyr::build_sql("MINUTE(", x, ")"),
      second = function(x) dbplyr::build_sql("SECOND(", x, ")"),

      # Date arithmetic
      today = function() dbplyr::sql("CURRENT_DATE()"),
      now = function() dbplyr::sql("CURRENT_TIMESTAMP()"),

      # Date parsing and formatting
      ymd = function(x) dbplyr::build_sql("DATE(", x, ")"),
      ymd_hms = function(x) dbplyr::build_sql("TIMESTAMP(", x, ")"),
      dmy = function(x) dbplyr::build_sql("TO_DATE(", x, ", 'dd/MM/yyyy')"),
      mdy = function(x) dbplyr::build_sql("TO_DATE(", x, ", 'MM/dd/yyyy')"),

      # Date/time manipulation
      floor_date = function(x, unit = "day") {
        switch(
          unit,
          "second" = dbplyr::build_sql("DATE_TRUNC('second', ", x, ")"),
          "minute" = dbplyr::build_sql("DATE_TRUNC('minute', ", x, ")"),
          "hour" = dbplyr::build_sql("DATE_TRUNC('hour', ", x, ")"),
          "day" = dbplyr::build_sql("DATE_TRUNC('day', ", x, ")"),
          "week" = dbplyr::build_sql("DATE_TRUNC('week', ", x, ")"),
          "month" = dbplyr::build_sql("DATE_TRUNC('month', ", x, ")"),
          "quarter" = dbplyr::build_sql("DATE_TRUNC('quarter', ", x, ")"),
          "year" = dbplyr::build_sql("DATE_TRUNC('year', ", x, ")"),
          dbplyr::build_sql("DATE_TRUNC('day', ", x, ")")
        )
      }
    ),

    aggregate = dbplyr::sql_translator(
      .parent = dbplyr::base_agg,
      n = function() dbplyr::sql("COUNT(*)"),
      count = function() dbplyr::sql("COUNT(*)"),
      n_distinct = function(..., na.rm = NULL) {
        na.rm <- na.rm %||% FALSE
        if (na.rm) {
          dbplyr::build_sql(
            "COUNT(DISTINCT",
            list(...) |>
              lapply(
                function(x) {
                  # consider NaN values as NA to match the `na.rm = TRUE`
                  # behavior of `dplyr::n_distinct()`
                  dbplyr::build_sql("NANVL(", x, ", NULL)")
                }
              ),
            ")"
          )
        } else {
          dbplyr::build_sql(
            "COUNT(DISTINCT",
            list(...) |>
              lapply(
                function(x) {
                  # wrap each expression in a Spark array to ensure `NULL`
                  # values are counted
                  dbplyr::build_sql("ARRAY(", x, ")")
                }
              ),
            ")"
          )
        }
      },
      cor = dbplyr::sql_aggregate_2("CORR"),
      cov = dbplyr::sql_aggregate_2("COVAR_SAMP"),
      sd = dbplyr::sql_aggregate("STDDEV_SAMP", "sd"),
      var = dbplyr::sql_aggregate("VAR_SAMP", "var"),
      weighted.mean = function(x, w) {
        weighted_mean_sql(x, w)
      }
    ),

    window = dbplyr::sql_translator(
      .parent = dbplyr::base_win,
      lag = function(x, n = 1L, default = NA, order_by = NULL) {
        dbplyr::base_win$lag(
          x = x,
          n = as.integer(n),
          default = default,
          order = order_by
        )
      },
      lead = function(x, n = 1L, default = NA, order_by = NULL) {
        dbplyr::base_win$lead(
          x = x,
          n = as.integer(n),
          default = default,
          order = order_by
        )
      },
      count = function() {
        dbplyr::win_over(
          dbplyr::sql("COUNT(*)"),
          partition = dbplyr::win_current_group()
        )
      },
      n_distinct = dbplyr::win_absent("DISTINCT"),
      cor = win_recycled_params("CORR"),
      cov = win_recycled_params("COVAR_SAMP"),
      sd = dbplyr::win_recycled("STDDEV_SAMP"),
      var = dbplyr::win_recycled("VAR_SAMP"),
      cumprod = function(x) {
        dbplyr::win_over(
          dbplyr::build_sql("SPARKLYR_CUMPROD(", x, ")"),
          partition = dbplyr::win_current_group(),
          order = dbplyr::win_current_order()
        )
      },
      weighted.mean = function(x, w) {
        dbplyr::win_over(
          weighted_mean_sql(x, w),
          partition = dbplyr::win_current_group()
        )
      }
    )
  )

  dbplyr::sql_variant(
    scalar = spark_base_sql_variant$scalar,
    aggregate = spark_base_sql_variant$aggregate,
    window = spark_base_sql_variant$window
  )
}

# Override dbplyr collect method for proper progress timing
#' Collect query results with proper progress timing for Databricks
#' @param con A DatabricksConnection object
#' @param sql SQL query to execute
#' @param n Maximum number of rows to collect (-1 for all)
#' @param warn_incomplete Whether to warn if results were truncated
#' @param ... Additional arguments
#' @return A data frame with query results
#' @export
#' @method db_collect DatabricksConnection
db_collect.DatabricksConnection <- function(con, sql, n = -1, warn_incomplete = TRUE, ...) {
  # Use dbGetQuery which already has proper progress handling
  out <- dbGetQuery(con, sql, show_progress = TRUE)
  
  # Apply row limit if specified
  if (n > 0 && nrow(out) > n) {
    out <- out[1:n, ]
    if (warn_incomplete) {
      warning("Only first ", n, " results retrieved. Use n = -1 to retrieve all.",
              call. = FALSE)
    }
  }
  
  out
}
