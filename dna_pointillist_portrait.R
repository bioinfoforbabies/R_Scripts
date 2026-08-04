# DNA Pointillist Portrait
#
# A DNA sequence is converted into a multi-scale, reverse-complement invariant
# k-mer fingerprint. Variable-size dots sample that hidden image to create a
# dense decorative portrait. The implementation uses base R only.
#
# HOW TO RUN
# ----------
# This file defines the dna_pointillist_portrait() function. Source the file,
# then call the function with a FASTA file (or a DNA sequence) as its first
# argument.
#
# From R or RStudio:
#
#   source("dna_pointillist_portrait.R")
#   dna_pointillist_portrait(
#     sequence = "path/to/sequence.fasta",
#     out = "output/portrait.png",
#     quality = "standard"
#   )
#
# From a terminal in the directory containing this script:
#
#   Rscript -e 'source("dna_pointillist_portrait.R"); dna_pointillist_portrait(sequence = "path/to/sequence.fasta", out = "output/portrait.png", quality = "standard", show_plot = FALSE)'
#
# A literal DNA string can be used instead of a FASTA path (it must contain at
# least 32 A/C/G/T bases):
#
#   dna_pointillist_portrait(
#     sequence = "ACGTACGTACGTACGTACGTACGTACGTACGT",
#     out = "output/from_sequence.png",
#     quality = "preview"
#   )
#
# ARGUMENTS
# ---------
# sequence       Required. A path to a FASTA file or one DNA string. FASTA
#                headers are ignored, lowercase is accepted, and characters
#                other than A, C, G, and T are removed. At least 32 valid bases
#                must remain.
# out            Output PNG path. Parent directories are created as needed.
#                Default: "output/dna_pointillist_portrait.png".
# quality        Rendering detail: "preview" (fast, 1400 px), "standard"
#                (balanced, 3000 px), or "gallery" (slowest, 5000 px).
#                Default: "preview".
# palette_family Optional fixed colour palette. Use NULL to select a palette
#                from the DNA. Available names: "pastel_garden",
#                "coastal_light", "spring_mineral", "soft_tropical", "dawn",
#                and "botanical_bloom". Default: NULL.
# aspect         Artwork width divided by artwork height. Values above 1 make
#                a landscape image; values below 1 make a portrait image.
#                Default: 1.25.
# intensity      Positive multiplier for dot opacity. Smaller values are softer;
#                larger values are more saturated. Default: 1.15.
# show_border    TRUE draws a thin gallery border; FALSE removes it.
#                Default: TRUE.
# show_metadata  TRUE adds a footer containing the label, sequence length, GC
#                percentage, and base composition. Default: TRUE.
# label          Name displayed in the metadata footer. NULL uses the FASTA
#                filename, or "DNA sequence" for literal sequence input.
#                Default: NULL.
# show_plot      TRUE also draws the result on the active graphics device (for
#                example, the RStudio Plots pane). It only works in an
#                interactive R session. Default: interactive(), which is FALSE
#                when run with Rscript.
# output_width   PNG width in pixels. NULL uses the width selected by quality:
#                1400, 3000, or 5000 pixels. Default: NULL.
# dpi            PNG resolution metadata in dots per inch. Default: 300.
#
# Example using every optional argument:
#
#   dna_pointillist_portrait(
#     sequence = "path/to/sequence.fasta",
#     out = "output/gallery_portrait.png",
#     quality = "gallery",
#     palette_family = "botanical_bloom",
#     aspect = 0.8,
#     intensity = 1.25,
#     show_border = TRUE,
#     show_metadata = TRUE,
#     label = "Sample 01",
#     show_plot = TRUE,
#     output_width = 4000L,
#     dpi = 300L
#   )

dpp_read_sequence <- function(sequence) {
  if (length(sequence) != 1L || is.na(sequence)) {
    stop("sequence must be one DNA string or one FASTA path")
  }
  if (file.exists(sequence)) {
    lines <- readLines(sequence, warn = FALSE)
    body <- lines[!grepl("^>", lines)]
    if (!length(body) && length(lines) == 1L &&
        grepl("^>[ACGTNacgtn]{24,}$", lines[1L])) {
      sequence <- substring(lines[1L], 2L)
    } else {
      sequence <- paste(body, collapse = "")
    }
  }
  sequence <- toupper(gsub("[^ACGT]", "", sequence))
  if (nchar(sequence) < 32L) stop("at least 32 A/C/G/T bases are required")
  sequence
}

dpp_base_values <- function(sequence) {
  match(strsplit(sequence, "", fixed = TRUE)[[1L]], c("A", "C", "G", "T")) - 1L
}

dpp_reverse_complement <- function(sequence) {
  bases <- strsplit(sequence, "", fixed = TRUE)[[1L]]
  paste0(c(A = "T", C = "G", G = "C", T = "A")[rev(bases)], collapse = "")
}

dpp_rc_codes <- function(k) {
  ids <- 0:(4^k - 1L)
  work <- ids
  rc <- integer(length(ids))
  for (i in seq_len(k)) {
    digit <- work %% 4L
    work <- work %/% 4L
    rc <- rc * 4L + (3L - digit)
  }
  rc
}

dpp_kmer_counts <- function(values, k) {
  n <- length(values)
  m <- n - k + 1L
  if (m < 1L) return(integer(4^k))
  codes <- numeric(m)
  for (j in 0:(k - 1L)) {
    codes <- codes + values[(1L + j):(m + j)] * 4^(k - j - 1L)
  }
  raw_counts <- tabulate(as.integer(codes) + 1L, nbins = 4^k)
  canonical <- pmin(0:(4^k - 1L), dpp_rc_codes(k))
  combined <- integer(4^k)
  active <- which(raw_counts > 0L)
  for (i in active) {
    target <- canonical[i] + 1L
    combined[target] <- combined[target] + raw_counts[i]
  }
  combined
}

dpp_profile <- function(sequence) {
  sequence <- dpp_read_sequence(sequence)
  values <- dpp_base_values(sequence)
  max_k <- min(6L, max(3L, floor(log(length(values), base = 4)) + 1L))
  ks <- 2L:max_k
  counts <- lapply(ks, function(k) dpp_kmer_counts(values, k))
  names(counts) <- paste0("k", ks)

  composition <- tabulate(values + 1L, nbins = 4L) / length(values)
  signature <- unlist(lapply(counts, function(x) x / max(1, sum(x))))
  weights <- ((seq_along(signature) * 104729) %% 1000003) + 1
  seed <- as.integer((sum(signature * weights) * 1e9 + length(values) * 7919) %%
                       2147483646) + 1L
  palette_index <- as.integer((sum(counts[[length(counts)]] *
                                      seq_along(counts[[length(counts)]])) +
                                 round(sum(composition[c(2L, 3L)]) * 1000)) %% 6L) + 1L

  list(
    sequence = sequence,
    values = values,
    length = length(values),
    composition = setNames(composition, c("A", "C", "G", "T")),
    ks = ks,
    counts = counts,
    seed = seed,
    palette_index = palette_index
  )
}

dpp_shift <- function(x, rows, cols) {
  nr <- nrow(x); nc <- ncol(x)
  ri <- pmin(nr, pmax(1L, seq_len(nr) - rows))
  ci <- pmin(nc, pmax(1L, seq_len(nc) - cols))
  x[ri, ci, drop = FALSE]
}

dpp_blur <- function(x, passes = 1L) {
  for (i in seq_len(passes)) {
    x <- (4 * x + dpp_shift(x, 1L, 0L) + dpp_shift(x, -1L, 0L) +
            dpp_shift(x, 0L, 1L) + dpp_shift(x, 0L, -1L)) / 8
  }
  x
}

dpp_add_blob <- function(surface, x, y, radius_x, radius_y, amount) {
  nr <- nrow(surface); nc <- ncol(surface)
  col_min <- max(1L, floor(x - radius_x * 2.2))
  col_max <- min(nc, ceiling(x + radius_x * 2.2))
  row_min <- max(1L, floor(y - radius_y * 2.2))
  row_max <- min(nr, ceiling(y + radius_y * 2.2))
  if (col_min > col_max || row_min > row_max) return(surface)
  cols <- col_min:col_max
  rows <- row_min:row_max
  xx <- matrix(rep((cols - x) / max(1, radius_x), each = length(rows)),
               length(rows), length(cols))
  yy <- matrix(rep((rows - y) / max(1, radius_y), length(cols)),
               length(rows), length(cols))
  mask <- exp(-0.5 * (xx^2 + yy^2))
  surface[rows, cols] <- surface[rows, cols] + amount * mask
  surface
}

dpp_code_geometry <- function(code, k) {
  digits <- integer(k)
  work <- code
  for (i in k:1L) {
    digits[i] <- work %% 4L
    work <- work %/% 4L
  }
  corners_x <- c(0, 0, 1, 1)
  corners_y <- c(0, 1, 1, 0)
  x <- 0.5; y <- 0.5
  for (digit in digits) {
    x <- (x + corners_x[digit + 1L]) / 2
    y <- (y + corners_y[digit + 1L]) / 2
  }
  dominant <- which.max(tabulate(digits + 1L, nbins = 4L))
  c(x = x, y = y, dominant = dominant)
}

dpp_normalize <- function(x) {
  limits <- range(x, finite = TRUE)
  if (!all(is.finite(limits)) || diff(limits) == 0) return(x * 0)
  (x - limits[1L]) / diff(limits)
}

dpp_hidden_image <- function(profile, height = 260L, aspect = 1.25) {
  height <- max(120L, as.integer(height))
  width <- as.integer(round(height * aspect))
  density <- matrix(0, height, width)
  channels <- array(0, c(height, width, 4L))
  set.seed(profile$seed)

  layer_weights <- seq(0.34, 0.10, length.out = length(profile$ks))
  for (layer_id in seq_along(profile$ks)) {
    k <- profile$ks[layer_id]
    counts <- profile$counts[[layer_id]]
    active <- which(counts > 0) - 1L
    layer <- matrix(0, height, width)
    layer_channels <- array(0, c(height, width, 4L))
    radius <- max(1.4, height * (0.085 / 1.65^(k - 2L)))
    angle <- ((profile$seed %% (67L + k * 11L)) / (67 + k * 11) - 0.5) * 0.85

    for (code in active) {
      geometry <- dpp_code_geometry(code, k)
      x <- geometry["x"] - 0.5
      y <- geometry["y"] - 0.5
      xr <- x * cos(angle) - y * sin(angle)
      yr <- x * sin(angle) + y * cos(angle)
      warped_x <- xr + 0.10 * sin(yr * pi * (2 + profile$composition["G"] * 3))
      warped_y <- yr + 0.08 * sin(xr * pi * (2 + profile$composition["T"] * 3))
      px <- (0.5 + warped_x * 0.88) * width
      py <- (0.5 + warped_y * 0.82) * height
      abundance <- sqrt(counts[code + 1L] / max(counts))
      layer <- dpp_add_blob(layer, px, py, radius * aspect, radius, abundance)
      group <- as.integer(geometry["dominant"])
      layer_channels[, , group] <- dpp_add_blob(
        layer_channels[, , group], px, py, radius * aspect, radius, abundance
      )
    }
    layer <- dpp_normalize(layer)
    density <- density + layer_weights[layer_id] * layer
    for (group in seq_len(4L)) {
      layer_channels[, , group] <- dpp_normalize(layer_channels[, , group])
      channels[, , group] <- channels[, , group] +
        layer_weights[layer_id] * layer_channels[, , group]
    }
  }

  density <- dpp_normalize(density)
  broad <- dpp_blur(density, passes = max(8L, round(height / 18)))
  broad <- dpp_normalize(broad)

  # Reinforce DNA-derived peaks to create a readable composition at distance.
  peak_field <- broad
  masses <- 3L + profile$seed %% 5L
  mass_layer <- matrix(0, height, width)
  for (i in seq_len(masses)) {
    index <- which.max(peak_field)
    row <- ((index - 1L) %% height) + 1L
    col <- ((index - 1L) %/% height) + 1L
    radius <- height * runif(1, 0.08, 0.17)
    mass_layer <- dpp_add_blob(mass_layer, col, row, radius * aspect,
                               radius * runif(1, 0.72, 1.18), runif(1, 0.7, 1.2))
    peak_field <- dpp_add_blob(peak_field, col, row, radius * 1.45,
                               radius * 1.45, -2)
  }
  mass_layer <- dpp_normalize(pmax(mass_layer, 0))
  density <- dpp_normalize(0.42 * density + 0.34 * broad + 0.24 * mass_layer)

  dx <- abs(dpp_shift(density, 0L, 1L) - dpp_shift(density, 0L, -1L))
  dy <- abs(dpp_shift(density, 1L, 0L) - dpp_shift(density, -1L, 0L))
  edges <- dpp_normalize(sqrt(dx^2 + dy^2))
  for (group in seq_len(4L)) channels[, , group] <- dpp_normalize(channels[, , group])

  list(density = density, edges = edges, channels = channels,
       width = width, height = height, masses = masses)
}

dpp_palettes <- function() {
  list(
    pastel_garden = c("#A8D5C2", "#C9B4E5", "#F3AFC3", "#F3D27A", "#A9C9F4"),
    coastal_light = c("#8FD6D2", "#B8E1D4", "#F5BBC3", "#F1B29B", "#9EC5E5"),
    spring_mineral = c("#73C9C5", "#C3AFE3", "#F4B79C", "#EBCB72", "#9CCFAF"),
    soft_tropical = c("#F0A4B8", "#F3C06E", "#75CFCA", "#C1A8DF", "#B7D99B"),
    dawn = c("#A8C8E8", "#E8A9BD", "#F2B891", "#C5A7CB", "#EACD76"),
    botanical_bloom = c("#A7C7A2", "#85BDB5", "#D9A2B3", "#B7A4D4", "#D5B56D")
  )
}

dpp_palette <- function(profile, family = NULL) {
  palettes <- dpp_palettes()
  if (is.null(family)) family <- names(palettes)[profile$palette_index]
  if (!family %in% names(palettes)) {
    stop("palette family must be one of: ", paste(names(palettes), collapse = ", "))
  }
  colors <- palettes[[family]]
  rotation <- profile$seed %% length(colors)
  colors <- colors[((seq_along(colors) + rotation - 1L) %% length(colors)) + 1L]
  list(name = family, colors = colors, background = "#F8F5EF")
}

dpp_sample_dots <- function(hidden, profile, palette, n, layer) {
  density <- hidden$density
  edges <- hidden$edges
  probability <- switch(layer,
    ground = 0.30 + density^0.85,
    structure = 0.03 + density^1.45 * (0.30 + 1.7 * edges),
    focal = 0.005 + density^2.4 * (0.18 + edges)
  )
  index <- sample.int(length(density), n, replace = TRUE,
                      prob = as.vector(probability))
  row <- ((index - 1L) %% hidden$height) + 1L
  col <- ((index - 1L) %/% hidden$height) + 1L
  local_density <- density[index]
  local_edge <- edges[index]

  channel_values <- vapply(seq_len(4L), function(group) {
    hidden$channels[, , group][index]
  }, numeric(n))
  dominant <- max.col(channel_values, ties.method = "random")
  accent <- local_edge > stats::quantile(edges, 0.86) & runif(n) < 0.28
  color_id <- ((dominant + profile$seed %% 4L - 1L) %% 4L) + 1L
  color_id[accent] <- 5L

  parameters <- switch(layer,
    ground = list(meanlog = -2.25, sdlog = 0.48, alpha = c(0.20, 0.38)),
    structure = list(meanlog = -1.05, sdlog = 0.55, alpha = c(0.24, 0.46)),
    focal = list(meanlog = 0.34, sdlog = 0.58, alpha = c(0.08, 0.22))
  )
  size <- rlnorm(n, parameters$meanlog, parameters$sdlog)
  size <- size * (0.72 + 0.75 * local_edge + 0.35 * local_density)
  alpha <- runif(n, parameters$alpha[1L], parameters$alpha[2L])

  data.frame(
    x = (col - 1L + runif(n)) / hidden$width,
    y = (row - 1L + runif(n)) / hidden$height,
    size = size,
    alpha = alpha,
    color = palette$colors[color_id]
  )
}

dpp_alpha_colors <- function(colors, alpha) {
  rgb_values <- grDevices::col2rgb(colors) / 255
  grDevices::rgb(rgb_values[1L, ], rgb_values[2L, ], rgb_values[3L, ], alpha = alpha)
}

dpp_layout <- function(width, aspect, show_border, metadata) {
  frame <- if (show_border) as.integer(round(width * 0.025)) else 0L
  footer <- if (is.null(metadata)) frame else as.integer(round(width * 0.085))
  art_width <- width - 2L * frame
  art_height <- as.integer(round(art_width / aspect))
  height <- frame + art_height + footer
  list(
    width = width, height = height, frame = frame, footer = footer,
    art_width = art_width, art_height = art_height,
    art_left = frame, art_right = frame + art_width,
    art_bottom = footer, art_top = footer + art_height
  )
}

dpp_draw <- function(layers, layout, background, show_border, metadata) {
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_par), add = TRUE)
  width <- layout$width
  height <- layout$height
  art_left <- layout$art_left
  art_right <- layout$art_right
  art_bottom <- layout$art_bottom
  art_top <- layout$art_top
  art_width <- layout$art_width
  art_height <- layout$art_height
  footer <- layout$footer

  graphics::par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i", bg = background)
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, width), ylim = c(0, height), asp = 1)
  graphics::rect(art_left, art_bottom, art_right, art_top,
                 col = background, border = NA)
  graphics::clip(art_left, art_right, art_bottom, art_top)
  for (layer in layers) {
    x <- art_left + layer$x * art_width
    y <- art_bottom + layer$y * art_height
    graphics::points(x, y, pch = 16, cex = layer$size,
                     col = dpp_alpha_colors(layer$color, layer$alpha))
  }
  graphics::clip(0, width, 0, height)
  if (show_border) {
    graphics::rect(art_left, art_bottom, art_right, art_top,
                   border = "#AAA196", lwd = 0.9)
    inset <- max(2, round(width * 0.0015))
    graphics::rect(art_left + inset, art_bottom + inset,
                   art_right - inset, art_top - inset,
                   border = "#DDD6CC", lwd = 0.45)
  }
  if (!is.null(metadata)) {
    graphics::text(width / 2, footer * 0.62, labels = metadata$name,
                   family = "serif", font = 2, cex = 0.82, col = "#49453F")
    graphics::text(width / 2, footer * 0.29, labels = metadata$details,
                   family = "sans", cex = 0.52, col = "#746E66")
  }
  invisible(layout)
}

dpp_render <- function(layers, out, width, aspect, dpi, background,
                       show_border = TRUE, metadata = NULL) {
  layout <- dpp_layout(width, aspect, show_border, metadata)
  directory <- dirname(out)
  if (!dir.exists(directory)) dir.create(directory, recursive = TRUE)
  grDevices::png(out, width = layout$width, height = layout$height,
                 res = dpi, bg = background)
  tryCatch(
    dpp_draw(layers, layout, background, show_border, metadata),
    finally = grDevices::dev.off()
  )
  invisible(out)
}

#' Create a decorative pointillist portrait from a DNA sequence.
#'
#' @param sequence DNA text or a FASTA path.
#' @param out Destination PNG.
#' @param quality preview, standard, or gallery.
#' @param palette_family Optional named pastel family; NULL lets DNA select it.
#' @param aspect Width divided by height.
#' @param intensity Multiplier for dot opacity; 1.15 is saturated pastel.
#' @param show_border Draw a thin gallery border around the artwork.
#' @param show_metadata Add a footer with filename and sequence composition.
#' @param label Optional display name; defaults to the FASTA filename.
#' @param show_plot Also draw the finished artwork in the RStudio Plots pane;
#'   defaults to TRUE in interactive sessions.
#' @param output_width Optional PNG width in pixels.
#' @param dpi PNG resolution metadata.
#' @return Invisible analysis, hidden image, palette, and sampled layers.
dna_pointillist_portrait <- function(
    sequence,
    out = "output/dna_pointillist_portrait.png",
    quality = c("preview", "standard", "gallery"),
    palette_family = NULL,
    aspect = 1.25,
    intensity = 1.15,
    show_border = TRUE,
    show_metadata = TRUE,
    label = NULL,
    show_plot = interactive(),
    output_width = NULL,
    dpi = 300L) {
  quality <- match.arg(quality)
  settings <- switch(quality,
    preview = list(grid = 180L, ground = 30000L, structure = 9000L,
                   focal = 1000L, width = 1400L),
    standard = list(grid = 280L, ground = 140000L, structure = 40000L,
                    focal = 4000L, width = 3000L),
    gallery = list(grid = 400L, ground = 400000L, structure = 110000L,
                   focal = 10000L, width = 5000L)
  )
  if (!is.numeric(intensity) || length(intensity) != 1L ||
      !is.finite(intensity) || intensity <= 0) {
    stop("intensity must be one positive number")
  }
  if (is.null(output_width)) output_width <- settings$width

  is_path <- nchar(sequence) < 4096L && file.exists(sequence)
  source_name <- if (!is.null(label)) {
    as.character(label)[1L]
  } else if (is_path) {
    basename(sequence)
  } else {
    "DNA sequence"
  }
  if (is.na(source_name) || !nzchar(source_name)) stop("label cannot be empty")
  profile <- dpp_profile(sequence)
  hidden <- dpp_hidden_image(profile, height = settings$grid, aspect = aspect)
  palette <- dpp_palette(profile, palette_family)
  set.seed(profile$seed)
  layers <- list(
    dpp_sample_dots(hidden, profile, palette, settings$focal, "focal"),
    dpp_sample_dots(hidden, profile, palette, settings$ground, "ground"),
    dpp_sample_dots(hidden, profile, palette, settings$structure, "structure")
  )
  layers <- lapply(layers, function(layer) {
    layer$alpha <- pmin(0.82, layer$alpha * intensity)
    layer
  })
  message(sprintf(
    "Portrait: %d bases | GC %.1f%% | %s | seed %d",
    profile$length, 100 * sum(profile$composition[c("G", "C")]),
    palette$name, profile$seed
  ))
  gc <- 100 * sum(profile$composition[c("G", "C")])
  composition_text <- paste(sprintf(
    "%s %.1f%%", names(profile$composition), 100 * profile$composition
  ), collapse = "  ")
  metadata <- if (isTRUE(show_metadata)) list(
    name = source_name,
    details = sprintf("%s BASES  |  GC %.1f%%  |  %s",
                      format(profile$length, big.mark = ",", scientific = FALSE),
                      gc, composition_text)
  ) else NULL
  dpp_render(layers, out, width = as.integer(output_width), aspect = aspect,
             dpi = dpi, background = palette$background,
             show_border = isTRUE(show_border), metadata = metadata)
  if (isTRUE(show_plot)) {
    if (interactive()) {
      display_width <- min(1600L, as.integer(output_width))
      display_layout <- dpp_layout(display_width, aspect,
                                   isTRUE(show_border), metadata)
      if (grDevices::dev.cur() == 1L) {
        display_height <- 8 * display_layout$height / display_layout$width
        grDevices::dev.new(width = 8, height = display_height,
                           noRStudioGD = FALSE)
      }
      dpp_draw(layers, display_layout, palette$background,
               isTRUE(show_border), metadata)
      message("Displayed DNA pointillist portrait on the active graphics device")
    } else {
      warning("show_plot = TRUE requires an interactive R or RStudio session")
    }
  }
  message("Saved DNA pointillist portrait: ", out)
  invisible(list(profile = profile, hidden = hidden, palette = palette,
                 layers = layers, metadata = metadata, out = out))
}
