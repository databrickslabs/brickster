# library(brickster)
# library(arrow)
# library(furrr)
# library(progressr)
#
# handlers("cli")
# plan(sequential)
#
# # Notes:
# # Wait 0 seconds
# # format default to arrow with external links
# # poll every 5 seconds
# #
# # Steps:
# # 1. Send Query
# # 2. If result, parse
# # 3. Otherwise poll for result
# # 4. Distribute fetching into arrow format
#
#
# query <- db_sql_query(
#   statement = "select * from zacdav.default.big_example LIMIT 1000000",
#   warehouse_id = "18243426e662e2ad",
#   format = "ARROW_STREAM",
#   disposition = "EXTERNAL_LINKS",
#   wait_timeout = "10s",
#   on_wait_timeout = "CONTINUE"
# )
#
# # poll till "SUCCEEDED"
# while (query$status$state %in% c("PENDING", "RUNNING")) {
#   Sys.sleep(2)
#   message("pending")
#   query <- db_sql_status(statement_id = query$statement_id)
# }
#
# # check if results were truncated and warn
# if (query$manifest$truncated) {
#   warning("Results are truncated...")
# }
#
# chunks <- seq.int(from = 0, length.out = query$manifest$total_chunk_count)
#
# chunks_to_tables <- function(statement_id, chunks, links_only = FALSE) {
#   p <- progressr::progressor(along = chunks)
#   purrr::map(chunks, function(x) {
#     chunk <- db_sql_result(query$statement_id, chunk = x)
#     table <- chunk$external_links[[1]]$external_link
#     print(table)
#     if (!links_only) {
#       table <- arrow::read_ipc_stream(file = table, as_data_frame = FALSE)
#     }
#     p(message = paste0("fetching chunk: ", x))
#     table
#   })
# }
#
# with_progress(chunk_tables <- chunks_to_tables(query$statement_id, chunks))
#
#
#
# arrow::read_ipc_stream(
#   file = db_sql_result(query$statement_id, chunk = 1)$external_links[[1]]$external_link,
#   as_data_frame = FALSE
# )
#
#
# result <- do.call(arrow::concat_tables, chunk_tables)
# result
#
#
# arrow::as_record_batch(chunk_tables[[1]])
# class((chunk_tables[[1]]))
#
# ####
# # # only works for CSV but saves needing to go multi-core route
# #
# # with_progress(chunk_links <- chunks_to_tables(query$statement_id, chunks, links_only = TRUE))
# #
# # library(duckdb)
# # library(DBI)
# #
# # chunk_links[[1]]
# #
# # conn <- DBI::dbConnect(duckdb::duckdb())
# # dbGetQuery(conn, "select * from read_csv_auto('https://e2-demo-field-eng-dbfs.s3.us-west-2.amazonaws.com/oregon-prod/1444828305810485.jobs/sql/extended/results_2023-11-03T13%3A09%3A55Z_9b14c6b9-8be2-4bce-b220-3a0b3d118a4b?X-Amz-Security-Token=IQoJb3JpZ2luX2VjEPT%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDnVzLXdlc3QtMi1maXBzIkYwRAIgZSyHdUi0o5vhf7kenVUOLWSXjfBeMiyjnxRtDrCiyKECIBN6fuDvbsS8V3wSm6gH8%2BlziYCznpZM5RehkZcq5%2FfkKtwDCC0QABoMNDE0MzUxNzY3ODI2IgxYNkjDOj7c5KykvlYquQNlnebmntDBqyZSfzzkhp5HZKnxkKcYuip15LE5x93iyEmGXSRlXv5DHTBlbNk1biNuHTZRDWtXsC6w%2FAZqrq%2BGXKlegxoZIELaAbEX2p94bHcC%2FUFa8o%2B9jBTZh7KeXvCZOUR8b8M9%2F8%2FdJ1ZmRMIyV7q%2Fa7D39bfYz4FLrzFQ8xs5Q%2B%2FmLvTaYT%2BL%2FxFdjtlPjuxfVM3CwkwvAvAb%2BwkGKMRLmwcq%2Bh8bDNMC7eKi9r0CAzr3x4Va6%2B5ibPuNjTqqDPONCLnH2QcVZS1oah6U3qQN6hbkvhsZRroKEJc0232HDz0qPdWZS%2B9G4Lew%2BY8tQ04MbeOkx6buQVnYi1UomEAk%2BJpPEeGGyrmcr6jQ8a36wlyhcqbZWl0zZA8INhHe2rAJQjDxDBL3IhqvTIHnlWZvAV0SzpEzD8l4Z%2FnBy2lwwXCH3MnVDqgpYNHUSOTAwx%2BqkgGZvaoWLKj4GoWPcoeQ1O%2FWqNwLSD%2FsBqwrQdzyfnpGRm81oJ6mBiRQr%2FdsXqbqAa44V9iGz4JhKicKjKC%2BVFcRyKhz%2BEo7UpVbu3TjqROiMOP6sFAgUzDQQ9IqJhZQXOGZhDMw4qOOqgY65AFaQw6xv4n44og2XQUWpj33wK0mjIT4HNnyZJmwdwG%2FGJNHr37Cn48b7%2FCVEw10OXLdJpQ8OfSeZ4ihybA9UsBZ%2BP%2BDqANQp6DjUSQ7ttUxkhoMTYYeJZT9mhgYlCn7590rFMd3BgXJimhYMvPRigmbPKKncX3Brvl4OhH2%2BKXMRKQJLoMEZNMADQXQBTtbzLZAbHX2Yrm2qby1SU9Ez6i8Mi5i95MuioL0pHWnk0xLbGDEykkXI0eVYnxoeaZatDuLUg5%2FdaESa2TZqfMqxWYtsETLCQll6wZuS%2BdEY1qRRu5s%2BJY%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20231102T121250Z&X-Amz-SignedHeaders=host&X-Amz-Expires=899&X-Amz-Credential=ASIAWA6KKHEJAE4HS7TR%2F20231102%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Signature=ed812a12073aa6b187ab4162b0be10047a54c7a5c23596950a92e9e46c6db845')")
# #
#
