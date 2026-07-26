# Print Methods -----------------------------------------------------------------

# Print villager trade object.
#' @export
print.bedrock_villager_trades <- function(x, ...) {
  tables <- x$professions
  tier_count <- sum(vapply(
    tables,
    function(table) length(table$levels),
    integer(1)
  ))
  group_count <- sum(vapply(
    tables,
    function(table) {
      sum(vapply(
        table$levels,
        function(level) length(level$groups),
        integer(1)
      ))
    },
    integer(1)
  ))
  candidate_count <- sum(vapply(
    tables,
    function(table) {
      sum(vapply(
        table$levels,
        function(level) {
          sum(vapply(
            level$groups,
            function(group) length(group$candidates),
            integer(1)
          ))
        },
        integer(1)
      ))
    },
    integer(1)
  ))
  cat('<bedrock_villager_trades>\n')
  cat('Minecraft Bedrock:', x$data_version$bedrock_version, '\n')
  cat('Professions:', paste(names(tables), collapse = ', '), '\n')
  cat('Tiers:', tier_count, '\n')
  cat('Groups:', group_count, '\n')
  cat('Candidates:', candidate_count, '\n')
  cat(
    'Retrieved:',
    format(
      x$data_version$retrieved_at,
      tz     = 'UTC',
      usetz  = TRUE
    ),
    '\n'
  )
  invisible(x)
}
