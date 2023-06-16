#--------------------------------------------------------------------------------------------
# File name: 		      test
# Creation date:      2022-03-22
# Author:          		César Landín
# Purpose:
# 	- Send test emails every hour
#--------------------------------------------------------------------------------------------

#################### Import packages #################### 
pacman::p_load(this.path, gmailr, lubridate, stringr,
               magrittr, readxl, writexl)
options(gargle_oauth_email = TRUE,
        gargle_oob_default = TRUE)
#########################################################

https://community.rstudio.com/t/gmailr-and-shiny-server-and-authentication/40684/6
https://github.com/tidyverse/googledrive/issues/274#issuecomment-528605315
https://github.com/r-lib/gmailr/issues/130
https://datawookie.github.io/emayili/
############################################################
##    (1): Define all functions and general parameters.   ##
############################################################
# (1.1): Import parameters as objects. #
# root_path <- str_replace(this.dir(), fixed("/scripts"), "")
root_path <- "/home/clu5015/reminder_system"
# (1.2): Authenticate client secret. #
gm_auth_configure(key = "1065652583536-9nip1otb0mijnjgniqrhv6h1aume42gr.apps.googleusercontent.com",
                  secret = "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")
gm_auth(email = "academic.remindr@gmail.com",
        path = "1065652583536-9nip1otb0mijnjgniqrhv6h1aume42gr.apps.googleusercontent.com",
        use_oob = TRUE)

# Cannot run this authentication in browser!


# Email from
email_from <- "academic.remindr@gmail.com"

# Define comma separated emails to send reminders.
current_emails <- "clandincca@hotmail.com"

rem_text <- str_c("<html><body>",
                  "Hello, <br><br>",
                  "This is an automated test email. <br><br>",
                  "Best, <br><br>",
                  "César",
                  "</body></html>")

rem_title <- "Test reminder system"

# Prepare and send email.
email_body <-
  gm_mime() %>%
  gm_to(current_emails) %>%  
  gm_from(email_from) %>%
  gm_subject(rem_title) %>%
  gm_html_body(rem_text)
gm_send_message(email_body)

############################################################
##    (1): Set up cronR.   ##
############################################################
# pacman::p_load(cronR)
# reminder_script <- file.path(root_path, "scripts", "server_test.R")
cmd <- cron_rscript(reminder_script)
cron_add(command = cmd,
         frequency = "56 13,15,17 * * 3", # Runs at 1:50, 3:50 and 5:50 PM on wednesdays
         id = "server_test",
         description = "test reminder system")
