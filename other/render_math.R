# Configuration -------------------------------------------------------------

# Locate note directory.
arguments <- commandArgs(trailingOnly = FALSE)
file_argument <- grep('^--file=', arguments, value = TRUE)
if (length(file_argument) == 1L) {
  script_path <- sub('^--file=', '', file_argument)
  note_directory <- dirname(normalizePath(script_path))
} else {
  note_directory <- normalizePath(getwd())
}

# Locate Quarto from PATH or a bundled macOS installation.
quarto_candidates <- unique(
  c(
    unname(Sys.which('quarto')),
    paste0(
      '/Applications/RStudio.app/Contents/Resources/',
      'app/quarto/bin/quarto'
    ),
    paste0(
      '/Applications/Positron.app/Contents/Resources/',
      'app/quarto/bin/quarto'
    )
  )
)
quarto_candidates <- quarto_candidates[
  nzchar(quarto_candidates) &
    file.exists(quarto_candidates)
]
if (length(quarto_candidates) == 0L) {
  stop(
    'Quarto is required to render the mathematics note.',
    call. = FALSE
  )
}
quarto <- quarto_candidates[[1L]]

# Note Rendering ------------------------------------------------------------

# Render note from its source directory.
original_directory <- getwd()
on.exit(setwd(original_directory), add = TRUE)
setwd(note_directory)
render_output <- system2(
  quarto,
  args = c('render', 'math.qmd'),
  stdout = TRUE,
  stderr = TRUE
)
render_status <- attr(render_output, 'status')
if (is.null(render_status)) {
  render_status <- 0L
}
if (render_status != 0L) {
  stop(
    paste(
      c('Quarto failed to render the mathematics note.', render_output),
      collapse = '\n'
    ),
    call. = FALSE
  )
}

# Output --------------------------------------------------------------------

# Verify output and remove temporary build products.
if (!file.exists('math.pdf')) {
  stop('Quarto did not produce math.pdf.', call. = FALSE)
}
unlink('.quarto', recursive = TRUE)
unlink('_freeze', recursive = TRUE)
unlink('.gitignore')
message('Rendered math.pdf.')
