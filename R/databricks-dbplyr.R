#' dbplyr Backend for Databricks SQL
#'
#' @description
#' This file implements dbplyr backend support for Databricks SQL warehouses,
#' enabling dplyr syntax to be translated to Databricks SQL.
#'
#' @importFrom dbplyr sql_variant sql_translator base_scalar base_agg base_win
#' @importFrom dbplyr sql_prefix sql sql_table_analyze sql_quote sql_query_fields
#' @importFrom dbplyr translate_sql dbplyr_edition sql_query_save simulate_spark_sql
#' @importFrom glue glue_sql
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
