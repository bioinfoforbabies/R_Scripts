# 5. Set a script to run itself at 2 AM
# Card: "Schedule It in R, Skip the OS Scheduler Menus"

## Mac / Linux: cronR
# install.packages("cronR")
library(cronR)

cmd <- cron_rscript("my_daily_analysis.R")  # path to the script to run

cron_add(
  command  = cmd,
  frequency = "daily",
  at        = "02:00",
  id        = "daily_analysis"
)

# cron_ls()                # view scheduled jobs
# cron_rm(id = "daily_analysis")  # remove the job


## Windows: taskscheduleR
# install.packages("taskscheduleR")
library(taskscheduleR)
#
taskscheduler_create(
   taskname  = "daily_analysis",
   rscript   = "my_daily_analysis.R",
   schedule  = "DAILY",
   starttime = "02:00")

# taskscheduler_ls()                     # view scheduled tasks
# taskscheduler_delete(taskname = "daily_analysis")  # remove the task
