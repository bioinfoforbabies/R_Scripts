# 1. Notify when a script finishes
# Card: "Stop Babysitting a Script That Takes Hours to Run"

# install.packages("beepr")
#library(beepr)

# --- your long-running step goes here ---
# e.g. a DADA2 step, a big join, a model fit
Sys.sleep(5)  # placeholder for the real long-running task
# -----------------------------------------

beepr::beep(sound = 2)  # plays a sound when the script reaches this line

# Desktop popup instead of a sound (cross-platform):
# install.packages("https://cran.r-project.org/src/contrib/Archive/notifier/notifier_1.0.0.tar.gz")
notifier::notify(title = "Script finished", msg = "Your run is done.")

