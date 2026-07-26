# Retrieval Helpers -------------------------------------------------------------

# Report package version.
.package_version <- function() {
  version <- tryCatch(
    as.character(utils::packageVersion('bedrocktrader')),
    error = function(error) '0.0.0.9000'
  )
  version
}

# Create GitHub request handle.
.github_handle <- function() {
  handle <- curl::new_handle(
    useragent = paste0('bedrocktrader/', .package_version())
  )
  headers <- c(Accept = 'application/vnd.github+json')
  token   <- Sys.getenv('GITHUB_PAT', unset = '')
  if (nzchar(token)) {
    headers <- c(headers, Authorization = paste('Bearer', token))
  }
  curl::handle_setheaders(handle, .list = as.list(headers))
  handle
}

# Extract GitHub error message.
.github_error_message <- function(content) {
  message <- tryCatch(
    jsonlite::fromJSON(rawToChar(content), simplifyVector = TRUE)$message,
    error = function(error) NULL
  )
  if (is.null(message) || length(message) != 1L || !nzchar(message)) {
    return(NULL)
  }
  message
}

# Retrieve URL bytes.
.fetch_bytes <- function(url) {
  response <- tryCatch(
    curl::curl_fetch_memory(url, handle = .github_handle()),
    error = function(error) {
      stop(
        'Unable to retrieve Mojang data from GitHub: ',
        conditionMessage(error),
        call. = FALSE
      )
    }
  )
  if (response$status_code < 200L || response$status_code >= 300L) {
    detail <- .github_error_message(response$content)
    if (response$status_code == 403L || response$status_code == 429L) {
      detail <- paste0(
        detail %||% 'GitHub request limit reached',
        '. Set GITHUB_PAT to use an authenticated request allowance'
      )
    }
    stop(
      'Unable to retrieve Mojang data from GitHub (HTTP ',
      response$status_code,
      if (!is.null(detail)) paste0(': ', detail) else '',
      ').',
      call. = FALSE
    )
  }
  response$content
}

# Select fallback value.
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Strip JSON comments.
.strip_json_comments <- function(content) {
  bytes      <- as.integer(content)
  byte_count <- length(bytes)
  output     <- integer(byte_count)
  output_n   <- 0L
  index      <- 1L
  state      <- 'plain'
  while (index <= byte_count) {
    current <- bytes[[index]]
    next_byte <- if (index < byte_count) bytes[[index + 1L]] else NA_integer_
    if (state == 'plain') {
      if (current == 34L) {
        state <- 'string'
      } else if (current == 47L && identical(next_byte, 47L)) {
        state <- 'line_comment'
        index <- index + 2L
        next
      } else if (current == 47L && identical(next_byte, 42L)) {
        state <- 'block_comment'
        index <- index + 2L
        next
      }
      output_n <- output_n + 1L
      output[[output_n]] <- current
    } else if (state == 'string') {
      output_n <- output_n + 1L
      output[[output_n]] <- current
      if (current == 92L && index < byte_count) {
        index <- index + 1L
        output_n <- output_n + 1L
        output[[output_n]] <- bytes[[index]]
      } else if (current == 34L) {
        state <- 'plain'
      }
    } else if (state == 'line_comment') {
      if (current %in% c(10L, 13L)) {
        state <- 'plain'
        output_n <- output_n + 1L
        output[[output_n]] <- current
      }
    } else if (state == 'block_comment') {
      if (current == 42L && identical(next_byte, 47L)) {
        state <- 'plain'
        index <- index + 2L
        next
      }
      if (current %in% c(10L, 13L)) {
        output_n <- output_n + 1L
        output[[output_n]] <- current
      }
    }
    index <- index + 1L
  }
  if (state == 'block_comment') {
    stop('Mojang JSON contains an unterminated block comment.', call. = FALSE)
  }
  as.raw(output[seq_len(output_n)])
}

# Parse JSON source.
.parse_json <- function(content, source_path) {
  cleaned <- .strip_json_comments(content)
  tryCatch(
    jsonlite::fromJSON(rawToChar(cleaned), simplifyVector = FALSE),
    error = function(error) {
      stop(
        'Unable to parse Mojang JSON at `',
        source_path,
        '`: ',
        conditionMessage(error),
        call. = FALSE
      )
    }
  )
}

# Calculate Git blob SHA.
.git_blob_sha <- function(content) {
  header <- c(
    charToRaw(paste0('blob ', length(content))),
    as.raw(0L)
  )
  digest::digest(
    c(header, content),
    algo      = 'sha1',
    serialize = FALSE
  )
}

# Describe pinned release.
.pinned_release <- function() {
  list(
    bedrock_version = .bedrock_version,
    release_date    = .bedrock_release_date,
    channel         = 'stable',
    release_tag     = .bedrock_release_tag
  )
}

# Retrieve pinned source file.
.fetch_pinned_file <- function(source_path) {
  expected_sha <- unname(.bedrock_blob_shas[[source_path]])
  if (is.null(expected_sha)) {
    stop(
      'No pinned checksum is registered for Mojang source `',
      source_path,
      '`.',
      call. = FALSE
    )
  }
  url <- paste0(
    .bedrock_raw_url,
    '/',
    .bedrock_release_tag,
    '/',
    source_path
  )
  content  <- .fetch_bytes(url)
  blob_sha <- .git_blob_sha(content)
  if (!identical(blob_sha, expected_sha)) {
    stop(
      'Source checksum mismatch for `',
      source_path,
      '` in Mojang release `',
      .bedrock_version,
      '`.',
      call. = FALSE
    )
  }
  content
}
