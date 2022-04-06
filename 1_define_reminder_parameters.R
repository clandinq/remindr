#********************************************************************************************
# File name: 		      1_define_reminer_parameters
# Creation date:      2022-03-22
# Author:          		César Landín
# Purpose:
# 	- Define reminder parameters and automate reminders.
#********************************************************************************************

#***************** Import packages *****************#
if (!require(pacman)) {install.packages("pacman")}
pacman::p_load(here, cronR, tidyverse)
#*************************************************** #

################################################################
##    (1): Define reminder parameters: MODIFY THIS SECTION.   ##
################################################################
# (1.1): Define general reminder parameters. #
# 1. Define short project name (max. 20 characters). For example: "Current RCT".
proj_name <- "project_name"

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
fut_conf_freq <- "60, 90, 120"

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
# (2.1): Show existing cron jobs. #
cron_ls()

# (2.2): Save parameters locally to read by reminder script. #
current_params <- tibble(proj_name = proj_name,
                         email_from = emails_from, 
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
write_csv(current_params, here("rem_parameters.csv"))
    
# (2.3): If any reminder is activated, run reminder script hourly. #
if (fut_conf_activate + conf_dl_activate + up_pres_activate + grant_dl_activate) {
  reminder_script <- here("2_create_send_reminders.R")
  cmd <- cron_rscript(reminder_script)
  cron_add(command = cmd, 
           frequency = "0 10,14,18 * * *", # Runs at 10:00, 14:00 and 18:00. Why? In case one reminder fails to send.
           id = paste0(proj_name, "_reminders"), 
           description = paste0("Send ", proj_name, " future conference, conference deadline, presentation and grant reminders."))
}
