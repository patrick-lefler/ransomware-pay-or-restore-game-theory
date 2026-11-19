# Internal prose word counter; never rendered. The "How to read / What it tells you" paragraphs
# (::: {.reader-note} divs) are excluded from the cap; .side-note divs count toward it.
PAGE_LIMITS <- c("index.qmd" = 650, "game.qmd" = 800, "map-reputation.qmd" = 950, "governance.qmd" = 600)
TOTAL_LIMIT <- 3000

count_words <- function(txt) {
  txt <- gsub("`r [^`]*`", " X ", txt)
  txt <- gsub("\\$\\$[\\s\\S]*?\\$\\$", " ", txt, perl = TRUE)
  txt <- gsub("\\\\\\[[\\s\\S]*?\\\\\\]", " ", txt, perl = TRUE)
  txt <- gsub("[!]?\\[([^]]*)\\]\\([^)]*\\)", " \\1 ", txt)
  txt <- gsub("[#*_]|:::+|\\{[^}]*\\}", " ", txt)
  w <- strsplit(trimws(txt), "[[:space:]]+")[[1]]
  sum(nzchar(w) & grepl("[[:alnum:]]", w))
}

split_prose <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  txt <- sub("^---\n[\\s\\S]*?\n---\n", "", txt, perl = TRUE)
  txt <- gsub("```\\{[^\n]*\\}\n[\\s\\S]*?\n```", "", txt, perl = TRUE)
  txt <- gsub("<!--[\\s\\S]*?-->", "", txt, perl = TRUE)
  rn <- ":::\\s*\\{\\.reader-note\\}\n[\\s\\S]*?\n:::"
  notes <- regmatches(txt, gregexpr(rn, txt, perl = TRUE))[[1]]
  txt <- gsub(rn, "", txt, perl = TRUE)
  lines <- strsplit(txt, "\n")[[1]]
  lines <- lines[!grepl("^\\s*\\|", lines)]
  list(prose = paste(lines, collapse = "\n"), notes = notes)
}

root <- if (file.exists("_quarto.yml")) "." else ".."
tb <- do.call(rbind, lapply(names(PAGE_LIMITS), \(f) {
  p <- file.path(root, f)
  if (!file.exists(p)) return(data.frame(page = f, prose = NA, limit = PAGE_LIMITS[[f]], reader_notes = NA))
  s <- split_prose(p)
  data.frame(page = f, prose = count_words(s$prose), limit = PAGE_LIMITS[[f]],
             reader_notes = sum(vapply(s$notes, count_words, 0)))
}))
print(tb, row.names = FALSE)
cat(sprintf("Prose total: %d / %d (reader notes excluded: %d words)\n",
            sum(tb$prose, na.rm = TRUE), TOTAL_LIMIT, sum(tb$reader_notes, na.rm = TRUE)))
