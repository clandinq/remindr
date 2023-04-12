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
options(gargle_oauth_email = TRUE)
#########################################################

# Define functions
gm_auth_configure <- function (key = "", secret = "", path = Sys.getenv("GMAILR_APP"), 
                               appname = "gmailr", ..., app = httr::oauth_app(appname, key, 
                                                                              secret, ...))  {
  if (!((nzchar(key) && nzchar(secret)) || nzchar(path))) {
    stop("Must supply either `key` and `secret` or `path`", 
         call. = FALSE)
  }
  if (nzchar(path)) {
    stopifnot(is_string(path))
    app <- gargle::oauth_app_from_json(path)
  }
  stopifnot(is.null(app) || inherits(app, "oauth_app"))
  .auth$set_app(app)
  invisible(.auth)
}

gm_auth <- function (email = gm_default_email(), path = NULL, scopes = "full", 
                        cache = gargle::gargle_oauth_cache(), use_oob = gargle::gargle_oob_default(), 
                        token = NULL) {
  scopes <- gm_scopes()[match.arg(scopes, names(gm_scopes()), 
                                  several.ok = TRUE)]
  app <- gm_oauth_app()
  cred <- gargle::token_fetch(scopes = scopes, app = app, email = email, 
                              path = path, package = "gmailr", cache = cache, use_oob = use_oob, 
                              token = token)
  if (!inherits(cred, "Token2.0")) {
    stop("Can't get Google credentials.\n", "Are you running gmailr in a non-interactive session? Consider:\n", 
         "  * Call `gm_auth()` directly with all necessary specifics.\n", 
         call. = FALSE)
  }
  .auth$set_cred(cred)
  .auth$set_auth_active(TRUE)
  invisible()
}


############################################################
##    (1): Define all functions and general parameters.   ##
############################################################
# (1.1): Import parameters as objects. #
# root_path <- str_replace(this.dir(), fixed("/scripts"), "")
root_path <- "/home/clu5015/reminder_system"
# (1.2): Authenticate client secret. #
gm_auth_configure(key = "1065652583536-9nip1otb0mijnjgniqrhv6h1aume42gr.apps.googleusercontent.com",
                  secret = "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")
gm_auth(email = "academic.remindr@gmail.com")

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
