make_inline_test_result <- function() {
  rows <- list(
    list("0", NULL), list("1", NULL),
    list("2", "two"), list("3", "three"),
    list("4", NULL), list("5", "five")
  )
  chunks <- purrr::map(0:2, function(index) {
    chunk <- list(
      chunk_index = index,
      row_offset = index * 2L,
      row_count = 2L,
      data_array = rows[index * 2L + seq_len(2L)]
    )
    if (index < 2L) {
      chunk$next_chunk_index <- index + 1L
    }
    chunk
  })

  list(
    chunks = chunks,
    response = list(
      statement_id = "stmt-inline",
      status = list(state = "SUCCEEDED"),
      manifest = list(
        format = "JSON_ARRAY",
        total_chunk_count = 3L,
        total_row_count = 6L,
        schema = list(columns = list(
          list(name = "id", type_name = "LONG"),
          list(name = "label", type_name = "STRING")
        )),
        chunks = purrr::map(chunks, function(chunk) {
          chunk[c("chunk_index", "row_offset", "row_count")]
        })
      ),
      result = chunks[[1]]
    )
  )
}
