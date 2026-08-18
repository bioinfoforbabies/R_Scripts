# 4. Copy from a table, paste straight into R
# Card: "No CSV, No Save Step, Just Paste"
# Base R only, no packages needed.

## Windows: copy a table (e.g. from a paper or webpage), then run:
df <- read.delim("clipboard")

## Mac: use a pipe to pbpaste instead
df <- read.delim(pipe("pbpaste"))

## Linux: use xclip (must be installed at the OS level, not an R package)
df <- read.delim(pipe("xclip -selection clipboard -o"))

## Send an R object back to the clipboard to paste elsewhere:
# Windows
write.table(df, "clipboard", sep = "\t", row.names = FALSE)

# Mac
write.table(df, pipe("pbcopy"), sep = "\t", row.names = FALSE)

# Linux
write.table(df, pipe("xclip -selection clipboard"), sep = "\t", row.names = FALSE)
