# 2. Watch a folder and auto-react to new files
# Card: "Have R Notice a New File Before You Do"

# install.packages("fs")
library(fs)

watch_dir <- "fastqc"             # folder to watch
processed <- character(0)         # files already handled
target_count <- 2                # stop once this many files show up

dir_create(watch_dir)

react_to_new_file <- function(file) {
  message("New file detected: ", file)
  # put your real action here, e.g. run QC, move the file, log it
}

repeat {
  current_files <- dir_ls(watch_dir)
  new_files <- setdiff(current_files, processed)
  
  if (length(new_files) > 0) {
    for (f in new_files) react_to_new_file(f)
    processed <- current_files
  }
  
  if (length(processed) >= target_count) {
    message("Target of ", target_count, " files reached. Stopping.")
    break
  }
  
  Sys.sleep(30)  # check every 30 seconds; adjust as needed
}

# Note: this is a polling loop, not a built-in "watch" function.
# For real use, run it as a background job (e.g. via Rscript + cron/taskscheduleR).