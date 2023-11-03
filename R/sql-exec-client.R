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
