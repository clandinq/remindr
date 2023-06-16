
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
