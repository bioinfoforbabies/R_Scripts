# R_Scripts

A collection of small, self-contained R scripts and one R Markdown deck. Most of the numbered scripts are short "recipe" snippets illustrating one practical R trick each (they read like companion code for short-form cards/posts); the two unnumbered files are a standalone generative-art function and a teaching deck.

## Scripts

### `01_notify_when_done.R`
Get an alert when a long-running script (e.g. a DADA2 step, a big join, a model fit) finishes, instead of babysitting the console.
- Plays a sound via `beepr::beep()`.
- Optionally shows a cross-platform desktop popup via `notifier::notify()`.
- Replace the `Sys.sleep(5)` placeholder with your real long-running code.

### `02_watch_folder.R`
Polls a directory and reacts whenever new files appear, useful for pipelines where files land asynchronously (e.g. FastQC output).
- Uses the `fs` package to list files in `watch_dir` (default `"fastqc"`).
- Calls `react_to_new_file()` for each newly detected file — customize this function with your real action (run QC, move the file, log it, etc.).
- Runs a `repeat` polling loop (checks every 30s) until `target_count` files have been seen. Not a true filesystem watcher — intended to be run as a background job (e.g. `Rscript` + cron / `taskscheduleR`) for real use.

### `03_pdf_handling.R`
Merge or split PDF files without opening a separate PDF application.
- Uses `pdftools::pdf_combine()` to merge multiple PDFs into one.
- Uses `pdftools::pdf_split()` to split a PDF into individual per-page files.

### `04_clipboard_direct.R`
Read a copied table straight into R (and write one back out) without saving an intermediate CSV. Base R only, no packages required.
- Windows: `read.delim("clipboard")` / `write.table(df, "clipboard", ...)`.
- Mac: `read.delim(pipe("pbpaste"))` / `write.table(df, pipe("pbcopy"), ...)`.
- Linux: `read.delim(pipe("xclip -selection clipboard -o"))` / `write.table(df, pipe("xclip -selection clipboard"), ...)` (requires `xclip` installed at the OS level).

### `05_schedule_script.R`
Schedule an R script to run itself automatically (e.g. daily at 2 AM) from within R, skipping the OS's native scheduler UI.
- Mac/Linux: uses the `cronR` package (`cron_rscript()` + `cron_add()`) to add a cron job.
- Windows: uses the `taskscheduleR` package (`taskscheduler_create()`) to add a Task Scheduler task.
- Includes commented examples for listing (`cron_ls()` / `taskscheduler_ls()`) and removing (`cron_rm()` / `taskscheduler_delete()`) the scheduled job.

### `dna_pointillist_portrait.R`
A larger, self-contained (base R only) generative-art tool that turns a DNA sequence into a decorative "pointillist" portrait PNG.
- Defines one main function, `dna_pointillist_portrait()`, plus supporting `dpp_*` helper functions (sequence parsing, canonical k-mer counting, a synthetic "hidden image" built from multi-scale reverse-complement-invariant k-mer signatures, pastel color palettes, and point-based rendering to PNG via base graphics).
- Input: a FASTA file path or a literal DNA string (≥ 32 A/C/G/T bases after cleaning).
- Output: a PNG "portrait" whose composition is deterministically derived from the sequence's k-mer fingerprint, with an optional metadata footer (sequence length, GC%, base composition).
- Key arguments: `sequence`, `out`, `quality` (`"preview"` / `"standard"` / `"gallery"` — trades render time for detail), `palette_family`, `aspect`, `intensity`, `show_border`, `show_metadata`, `label`, `show_plot`, `output_width`, `dpi`.
- Usage:
  ```r
  source("dna_pointillist_portrait.R")
  dna_pointillist_portrait(
    sequence = "path/to/sequence.fasta",
    out = "output/portrait.png",
    quality = "standard"
  )
  ```
  or from a terminal:
  ```sh
  Rscript -e 'source("dna_pointillist_portrait.R"); dna_pointillist_portrait(sequence = "path/to/sequence.fasta", out = "output/portrait.png", quality = "standard", show_plot = FALSE)'
  ```
  See the header comment in the script for the full argument reference and a fully-specified example call.

### `dplyr_basics_deck.Rmd`
An R Markdown teaching deck (knits to HTML) walking through core `dplyr` verbs using a small self-contained sample metadata table (`meta`: sample id, group, reads, batch).
- Covers `select()`, `filter()`, `mutate()`, `arrange()`, `group_by()` + `summarise()`, and chaining verbs with the native pipe (`|>`).
- Knit with `rmarkdown::render("dplyr_basics_deck.Rmd")` or the RStudio "Knit" button. Requires the `tidyverse` package.

## Requirements

Depending on which script you run, you'll need one or more of these packages: `beepr`, `notifier`, `fs`, `pdftools`, `cronR` (Mac/Linux) or `taskscheduleR` (Windows), `tidyverse`. `dna_pointillist_portrait.R` has no package dependencies (base R only). The clipboard script (`04`) needs `xclip` installed at the OS level on Linux.
