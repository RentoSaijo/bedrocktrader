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

# Retrieve stable version registry.
.stable_versions <- function() {
  registry_url <- paste0(
    .bedrock_raw_url,
    '/main/',
    .bedrock_version_path
  )
  registry <- .parse_json(
    .fetch_bytes(registry_url),
    .bedrock_version_path
  )
  registry_versions <- setdiff(names(registry), 'latest')
  supported <- vapply(
    registry_versions,
    function(version) {
      utils::compareVersion(version, .bedrock_minimum_version) >= 0L
    },
    logical(1)
  )
  versions <- registry_versions[supported]
  if (!length(versions)) {
    stop(
      'Mojang stable-version registry contains no supported releases.',
      call. = FALSE
    )
  }
  result <- data.frame(
    version      = unname(versions),
    release_date = as.Date(vapply(
      registry[versions],
      function(record) record$date,
      character(1)
    ), format = '%d-%m-%Y'),
    latest       = versions == registry$latest$version,
    stringsAsFactors = FALSE
  )
  result <- result[
    order(result$release_date, decreasing = TRUE),
    ,
    drop = FALSE
  ]
  rownames(result) <- NULL
  result
}

# Resolve stable release.
.resolve_release <- function(version = 'latest') {
  if (
    length(version) != 1L ||
    is.na(version) ||
    !is.character(version) ||
    !nzchar(version)
  ) {
    stop('`version` must be one nonempty character value.', call. = FALSE)
  }
  requested <- sub('^v', '', version)
  if (grepl('preview', requested, fixed = TRUE)) {
    stop('Preview releases are outside the supported version range.', call. = FALSE)
  }
  versions <- .stable_versions()
  if (identical(requested, 'latest')) {
    if (!any(versions$latest)) {
      stop(
        'Mojang latest stable release is below the supported version floor.',
        call. = FALSE
      )
    }
    resolved <- versions$version[which(versions$latest)[[1L]]]
  } else {
    if (!requested %in% versions$version) {
      stop(
        '`version` must be "latest" or a release returned by ',
        '`bedrock_versions()`.',
        call. = FALSE
      )
    }
    resolved <- requested
  }
  release_index <- match(resolved, versions$version)
  list(
    requested_version = requested,
    bedrock_version   = resolved,
    release_date      = versions$release_date[[release_index]],
    channel           = 'stable',
    release_tag       = paste0('v', resolved)
  )
}

# Retrieve directory manifest.
.fetch_directory_manifest <- function(release, directory) {
  url <- paste0(
    .bedrock_api_url,
    '/contents/',
    directory,
    '?ref=',
    release$release_tag
  )
  manifest <- .parse_json(.fetch_bytes(url), url)
  if (!is.list(manifest) || !length(manifest)) {
    stop(
      'Mojang release `',
      release$bedrock_version,
      '` returned an empty source manifest.',
      call. = FALSE
    )
  }
  manifest
}

# Retrieve manifest file.
.fetch_manifest_file <- function(entry, release) {
  required_fields <- c('path', 'sha', 'download_url')
  if (!is.list(entry) || !all(required_fields %in% names(entry))) {
    stop(
      'Mojang release `',
      release$bedrock_version,
      '` returned incomplete source metadata.',
      call. = FALSE
    )
  }
  content <- .fetch_bytes(entry$download_url)
  blob_sha <- .git_blob_sha(content)
  if (!identical(blob_sha, entry$sha)) {
    stop(
      'Source checksum mismatch for `',
      entry$path,
      '` in Mojang release `',
      release$bedrock_version,
      '`.',
      call. = FALSE
    )
  }
  content
}

# Retrieve direct source file.
.fetch_direct_file <- function(release, source_path) {
  url <- paste0(
    .bedrock_api_url,
    '/contents/',
    source_path,
    '?ref=',
    release$release_tag
  )
  entry <- .parse_json(.fetch_bytes(url), url)
  if (is.null(entry$content) || is.null(entry$encoding)) {
    stop(
      'Mojang release `',
      release$bedrock_version,
      '` returned incomplete source content for `',
      source_path,
      '`.',
      call. = FALSE
    )
  }
  if (!identical(entry$encoding, 'base64')) {
    stop('Mojang source content uses an unsupported encoding.', call. = FALSE)
  }
  content <- jsonlite::base64_dec(gsub('[\r\n]', '', entry$content))
  blob_sha <- .git_blob_sha(content)
  if (!identical(blob_sha, entry$sha)) {
    stop(
      'Source checksum mismatch for `',
      source_path,
      '` in Mojang release `',
      release$bedrock_version,
      '`.',
      call. = FALSE
    )
  }
  content
}
