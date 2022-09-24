#********************************************************************************************
# File name: 		      1_define_reminer_parameters
# Creation date:      2022-03-22
# Author:          		César Landín
# Purpose:
# 	- Define reminder parameters and automate reminders.
#********************************************************************************************

#***************** Import packages *****************#
if (!require(pacman)) {install.packages("pacman")}
pacman::p_load(this.path, tidyverse, writexl)
#*************************************************** #

################################################################
##    (1): Define reminder parameters: MODIFY THIS SECTION.   ##
################################################################
# (1.1): Define general reminder parameters. #
# 1. Define short project name (max. 20 characters). For example: "Health RCT".
# This is the project name that will be used in email headers.
proj_name <- "project name"

# 2. Define email to send reminders from and name for signature.
email_from <- "email"
name_from <- "name"

# 3. Define absolute path to client secret.
# Example: 
# secret_path <- "/Users/js/Documents/important/client_secret_349342394234.apps.googleusercontent.com.json"
secret_path <- "path_to_secret"

# (1.2): Define specific reminder parameters. #
### Define three parameters for each reminder type:
# 1) Activate this reminder type?
# 2) Define comma separated emails to send future conference reminders (e.g. "john.smith@gmail.com, jane.smith@hotmail.com").
# 3) Define comma separated frequency to send future conference reminders in days (e.g. "1, 2, 5, 10").

# 4. Parameters for future conference reminders.
fut_conf_activate <- FALSE
fut_conf_emails <- "emails"
fut_conf_freq <- "90, 120, 150"

# 5. Parameters for conference deadline reminders.
conf_dl_activate <- FALSE
conf_dl_emails <- "emails"
conf_dl_freq <- "0, 1, 7, 14"

# 6. Parameters for upcoming presentation reminders.
up_pres_activate <- FALSE
up_pres_emails <- "emails"
up_pres_freq <- "1, 7, 14"

# 7. Parameters for grant deadline reminders.
grant_dl_activate <- FALSE
grant_dl_emails <- "emails"
grant_dl_freq <- "0, 1, 7, 14"

###############################################################
##    (2): Automate reminders: DO NOT MODIFY THIS SECTION.   ##
###############################################################
# (2.1): Function to get currrent OS. #
define_os <- function() {
  output <- Sys.info()["sysname"]
  current_os <- case_when(output == "Darwin" ~ "mac",
                          output == "Windows" ~ "windows")
  return(current_os)
}

# (2.2): Save parameters locally to read by reminder script. #
current_params <- tibble(proj_name = proj_name,
                         name_from = name_from,
                         email_from = email_from, 
                         secret_path = secret_path,
                         # Parameters for future conference reminders.
                         fut_conf_activate = fut_conf_activate,
                         fut_conf_emails = fut_conf_emails,
                         fut_conf_freq = fut_conf_freq,
                         # Parameters for conference paper submission reminders.
                         conf_dl_activate = conf_dl_activate,
                         conf_dl_emails = conf_dl_emails,
                         conf_dl_freq = conf_dl_freq,
                         # Parameters for upcoming presentation reminders.
                         up_pres_activate = up_pres_activate,
                         up_pres_emails = up_pres_emails,
                         up_pres_freq = up_pres_freq,
                         # Parameters for grant deadline reminders.
                         grant_dl_activate = grant_dl_activate,
                         grant_dl_emails = grant_dl_emails,
                         grant_dl_freq = grant_dl_freq)
write_xlsx(current_params, file.path(this.dir(), "rem_parameters.xlsx"))

# (2.3): If any reminder is activated, set upp reminders depending on operating system. #
if (fut_conf_activate + conf_dl_activate + up_pres_activate + grant_dl_activate) {
  # Define path of reminder script.
  reminder_script <- file.path(this.dir(), "2_create_send_reminders.R")
  # Define current OS and set reminders.
  if (define_os() == "mac") {
    pacman::p_load(cronR)
    cmd <- cron_rscript(reminder_script)
    cron_add(command = cmd, 
             frequency = "0 10,14,18 * * *", # Runs at 10:00, 14:00 and 18:00. Why? In case one reminder fails to send.
             id = paste0(proj_name, "_reminders"), 
             description = paste0("Send ", proj_name, " future conference, conference deadline, presentation and grant reminders."))
  } else if (define_os() == "windows") {
    pacman::p_load(taskscheduleR)
    # Run reminders at 10:00, 14:00 and 18:00. Why? In case one reminder fails to send.
    reminder_script <- file.path(this.dir(), "2_create_send_reminders.R")
    taskscheduler_create(rscript = reminder_script, 
                         taskname = paste0(proj_name, "_reminders_10"), 
                         schedule = "DAILY", 
                         starttime = "10:00", 
                         startdate = format(as.Date("2022-01-01"), "%d/%m/%Y"))
    taskscheduler_create(rscript = reminder_script, 
                         taskname = paste0(proj_name, "_reminders_14"), 
                         schedule = "DAILY", 
                         starttime = "14:00",
                         startdate = format(as.Date("2022-01-01"), "%d/%m/%Y"))
    taskscheduler_create(rscript = reminder_script, 
                         taskname = paste0(proj_name, "_reminders_18"), 
                         schedule = "DAILY", 
                         starttime = "18:00",
                         startdate = format(as.Date("2022-01-01"), "%d/%m/%Y"))
  }
}
