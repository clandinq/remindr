#********************************************************************************************
# File name: 		      2_create_send_reminders.R
# Creation date:      2022-03-22
# Author:          		César Landín
# Purpose:
# 	- This script defines functions to prepare three type of reminder emails for conferences:
#     1. Reminders to check if future conferences have announced submission deadlines,
#     2. Reminders to send an abstract or paper to a conference,
#     3. Reminders to prepare slides for conferences.
#********************************************************************************************

#***************** Import packages *****************#
suppressMessages(
  if (!require(pacman)) {install.packages("pacman")}
)
pacman::p_load(this.path, gmailr, tidyverse, lubridate,
               magrittr)
options(gargle_oauth_email = TRUE)
#*************************************************** #

############################################################
##    (1): Define all functions and general parameters.   ##
############################################################
# (1.1): Import parameters as objects. #
current_params <- read_csv(file.path(this.dir(), "rem_parameters.csv"), col_types = cols())
for (c in colnames(current_params)) {
  assign(c, current_params %>% pull(c))
}

# (1.2): Authenticate client secret. #
gm_auth_configure(path = secret_path)

# (1.3): Define current date. #
todays_date <- lubridate::today()

# (1.4): Define activated reminders. Quit if none activated. #
activated_rems <- "fut_conf"[fut_conf_activate] %>% 
  append("conf_dl"[conf_dl_activate]) %>% 
  append("grant_dl"[grant_dl_activate]) %>% 
  append("up_pres"[up_pres_activate])
if (is_empty(activated_rems)) {quit(save = "no")}

# (1.5): Function that converts "days" to "day" #
clean_days_s <- function(string) {
  ifelse(str_detect(string, "1"), 
         str_replace(string, "s", ""), 
         string)
}

# (1.6): Function that checks variable exists AND is not NA. #
exists_not_na <- function(string) {
  if (exists(string)) {
    !is.na(eval(as.name(string)))
  } else {
    FALSE
  }
}   

#########################################################
##    (2): Loop over reminder types and conferences.   ##
#########################################################
# (2.1): Loop over reminder types. #
now()
for (rem in activated_rems) {
  
  # Import reminder file.
  rem_file <- case_when(rem == "fut_conf" ~ "rem_future_conferences.csv",
                        rem == "conf_dl" ~ "rem_conference_deadlines.csv",
                        rem == "grant_dl" ~ "rem_grant_deadlines.csv",
                        rem == "up_pres" ~ "rem_upcoming_presentations.csv")
  current_dataset <- read_csv(file.path(this.dir(), rem_file), col_types = cols()) %>% 
    mutate(deadline = ymd(deadline))
  
  # Define comma separated emails to send reminders.
  current_emails <- eval(as.name(paste0(rem, "_emails")))

  # Define reminder frequencies.
  current_freq <- eval(as.name(paste0(rem, "_freq"))) %>% 
    str_split(",") %>% 
    unlist() %>% 
    as.numeric()
  
  # Empty dataframe to fill out with results.
  current_results <- tibble()
  
  # Loop over conferences / presentations.
  for (row in 1:nrow(current_dataset)) {
    
    # Assign dataset variables as objects in environment.
    for (c in colnames(current_dataset)) {
      assign(c, current_dataset[row,] %>% pull(c))
    }
    
    # Define current dataset variable names.
    current_varnames <- colnames(current_dataset)
    
    # Check if reminders need to be sent if not marked as complete.
    if (complete == 0) {
      
      # Loop over reminder frequencies.
      sent_email <- 0
      for (f in current_freq) {
        
        # Define time until deadline and reminder title.
        dead_type <- ifelse(exists_not_na("dead_type"), dead_type, "")
        rem_description <- case_when(rem == "fut_conf" ~ "predicted deadline",
                                     rem == "conf_dl" ~ "paper submission deadline",
                                     rem == "grant_dl" ~ paste("grant", dead_type, "deadline"),
                                     rem == "up_pres" ~ dead_type)
        
        if (f == 0) {
          time_until_deadline <- "today"
          rem_title <- paste0("FINAL REMINDER - ", str_to_upper(rem_description), " TODAY")
        } else if (f >= 1 & f < 7) {
          time_until_deadline <- paste0(f, " days")
          rem_title <- paste0(str_to_upper(rem_description), " IN ", str_to_upper(clean_days_s(time_until_deadline)))
        } else if (f >= 7 & f < 29) {
          time_until_deadline <- paste0(round(time_length(days(f), unit = "weeks"), 0), " weeks")
          rem_title <- paste("Upcoming", rem_description)
        } else if (f >= 29) {
          time_until_deadline <- paste0(round(time_length(days(f), unit = "months"), 0), " months")
          rem_title <- paste("Upcoming", rem_description)
        }
        
        # Future conference reminders have same format independent of time to conference.
        rem_title <- ifelse(rem == "fut_conf", "Upcoming predicted conference deadline", rem_title)
        
        # Paste full email title.
        rem_title <- paste0(proj_name, " //// ", rem_title, ": ", as.character(deadline))
        
        # Check if reminder exists / has been sent. If doesn't exist, it hasn't been sent.
        notif_varname <- paste0("notif_", str_replace(time_until_deadline, " ", ""))
        rem_sent <- tryCatch((eval(as.name(notif_varname)) == 1),
                             error = function(e) {FALSE})
        
        # Send reminders depending on dates and reminder status.
        if (!rem_sent & # (1) reminder not sent yet, 
            sent_email == 0 & # (2) an email for same conference / presentation hasn't been sent in current run, and
            (deadline - todays_date) >= 0 & (deadline - todays_date) <= f) { # (3) within timeframe to send reminder
          
          # Assign reminder variable and add to list of variables to export.
          assign(notif_varname, 1)
          
          # Define reminder text.
          rem_text <- paste0("<html><body>",
                             "This is an automated reminder that the ", description,
                             ifelse(rem == "up_pres", 
                                    paste0(" will take place on ", deadline, ". <br><br>"),
                                    paste0(" has a ", rem_description, " coming up on ", deadline, ". <br><br>")),
                             ifelse(rem == "grant_dl",
                                    paste0("This grant requires the following deliverable: <br><br>", details, "<br><br>"), ""),
                             ifelse(exists_not_na("submission"), 
                                    ifelse(dead_type != "conference",
                                           paste("Please remember to submit the ", dead_type, " to ", submission, " as soon as possible. <br><br>"), ""),
                                    ""),
                             ifelse(exists_not_na("website"), paste("For more information, please refer to ", website, "<br><br>"), "."),
                             ifelse(exists_not_na("questions"), paste("For any questions, please contact ", questions, "<br><br>"), "."),
                             "Best, <br><br>",
                             name_from,
                             "</body></html>")
          
          # Prepare and send email.
          email_body <-
            gm_mime() %>%
            gm_to(current_emails) %>%  
            gm_from(email_from) %>%
            gm_subject(rem_title) %>%
            gm_html_body(rem_text)
          gm_send_message(email_body)
          
          # Flag email sent.
          print(paste(rem, "email sent"))
          sent_email <- 1
          
          # Alternative: reminder hasn't been sent but deadline still in future -> sent reminder as 0.
        } else if (!rem_sent & (deadline - todays_date) > f) {
          assign(notif_varname, 0)
        }
      }
    }
    
    # Append notification variables to list of current variable names.
    current_varnames <- c(current_varnames, ls()[str_detect(ls(), "notif") & !str_detect(ls(), "varname")]) %>% unique()
    
    # Save current parameters in dataframe.
    temp_row <- mget(current_varnames) %>% 
      as_tibble()
    current_results %<>% bind_rows(temp_row)
    rm(temp_row, list = current_varnames)
  }
  
  # Save updated csv.
  current_results %<>%
    mutate_at(vars(starts_with("notif_")), ~ifelse(is.na(.), 1, .)) %>% 
    mutate(complete = ifelse(rowSums(across(starts_with("notif_"))) == length(current_freq), 1, complete),
           deadline = str_replace_all(deadline, "-", "_"))
  write_csv(current_results, file.path(this.dir(), rem_file))
}

