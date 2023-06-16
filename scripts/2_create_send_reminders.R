#--------------------------------------------------------------------------------------------
# File name: 		      2_create_send_reminders.R
# Creation date:      2022-03-22
# Author:          		César Landín
# Purpose:
# 	- This script defines functions to prepare three type of reminder emails for conferences:
#     1. Reminders to check if future conferences have announced submission deadlines,
#     2. Reminders to send an abstract or paper to a conference,
#     3. Reminders to prepare slides for conferences.
#--------------------------------------------------------------------------------------------

#################### Import packages #################### 
pacman::p_load(this.path, gmailr, tidyverse, lubridate,
               magrittr, readxl, writexl)
options(gargle_oauth_email = TRUE)
#########################################################

############################################################
##    (1): Define all functions and general parameters.   ##
############################################################
# (1.1): Import parameters as objects. #
root_path <- str_replace(this.dir(), fixed("/scripts"), "")
current_params <- read_excel(file.path(root_path, "data", "rem_parameters.xlsx"))
for (c in colnames(current_params)) {
  assign(c, current_params %>% pull(c))
}

# (1.2): Authenticate client secret. #
gm_auth_configure(path = secret_path)
gm_auth(email = email_from)

# (1.3): Define current date. #
todays_date <- today()

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
    !is.na(eval(as.name(string))) & eval(as.name(string)) != "NA"
  } else {
    FALSE
  }
}   

#########################################################
##    (2): Loop over reminder types and conferences.   ##
#########################################################
# (2.1): Loop over reminder types. #
now()
for (rem_type in activated_rems) {
  
  # Import reminder file.
  rem_file <- case_when(rem_type == "fut_conf" ~ "rem_future_conferences.xlsx",
                        rem_type == "conf_dl" ~ "rem_conference_deadlines.xlsx",
                        rem_type == "grant_dl" ~ "rem_grant_deadlines.xlsx",
                        rem_type == "up_pres" ~ "rem_upcoming_presentations.xlsx")
  current_dataset <- read_excel(file.path(root_path, "data", rem_file)) %>% 
    mutate(deadline = ymd(deadline)) %>% 
    arrange(deadline)
  
  # Define comma separated emails to send reminders.
  current_emails <- eval(as.name(str_c(rem_type, "_emails")))
  
  # Define reminder frequencies.
  current_freq <- eval(as.name(str_c(rem_type, "_freq"))) %>% 
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
    complete <- ifelse(is.na(complete), FALSE, complete)
    if (complete == 0) {
      
      # Loop over reminder frequencies.
      sent_email <- 0
      for (f in current_freq) {
        
        # Define time until deadline and reminder title.
        dead_type <- ifelse(exists_not_na("dead_type"), dead_type, "")
        rem_description <- case_when(rem_type == "fut_conf" ~ "predicted deadline",
                                     rem_type == "conf_dl" ~ "paper submission deadline",
                                     rem_type == "grant_dl" ~ paste("grant", dead_type, "deadline"),
                                     rem_type == "up_pres" ~ 
                                       case_when(dead_type == "General presentation reminder" ~ "conference presentation",
                                                 dead_type == "Reminder to submit paper" ~ "conference paper submission deadline",
                                                 dead_type == "Reminder to submit slides" ~ "conference slide submission deadline"))
        
        # Define email titles.
        if (f == 0) {
          time_until_deadline <- "today"
          rem_title <- str_c("FINAL REMINDER - ", str_to_upper(rem_description), " TODAY")
        } else if (f >= 1 & f < 7) {
          time_until_deadline <- str_c(f, " days")
          rem_title <- str_c(str_to_upper(rem_description), " IN ", str_to_upper(clean_days_s(time_until_deadline)))
        } else if (f >= 7 & f < 29) {
          time_until_deadline <- str_c(round(time_length(days(f), unit = "weeks"), 0), " weeks")
          rem_title <- paste("Upcoming", rem_description)
        } else if (f >= 29) {
          time_until_deadline <- str_c(round(time_length(days(f), unit = "months"), 0), " months")
          rem_title <- paste("Upcoming", rem_description)
        }
        
        # Future conference reminders have same format independent of time to conference.
        rem_title <- ifelse(rem_type == "fut_conf", "Upcoming predicted conference deadline", rem_title)
        
        # Paste full email title.
        rem_title <- str_c(proj_name, " //// ", rem_title, ": ", as.character(deadline))
        
        # Check if reminder exists / has been sent. If doesn't exist, it hasn't been sent.
        notif_varname <- str_c("notif_", str_replace(time_until_deadline, " ", ""))
        rem_sent <- ifelse(eval(as.name(notif_varname)) %in% c(0, NA), 0, 1)
        
        # Send reminders depending on dates and reminder status.
        if (!rem_sent & # (1) reminder not sent yet, 
            sent_email == 0 & # (2) an email for same conference / presentation hasn't been sent in current run, and
            (deadline - todays_date) >= 0 & (deadline - todays_date) <= f) { # (3) within timeframe to send reminder
          # (3) within timeframe to send reminder
          # (deadline
          # today(tzone = "Australia/Sydney")
          
          # Assign reminder variable and add to list of variables to export.
          assign(notif_varname, 1)
          
          # Define reminder text.
          if (rem_type == "fut_conf") {
            # FUTURE CONFERENCE REMINDERS
            rem_text <- str_c("<html><body>",
                              "Hello, <br><br>",
                              "This is an automated reminder that the ", description, " is predicted to take place on ", conf_date, ". <br><br>",
                              "Please remember to check the website for up to date conference information: ", website, " <br><br>",
                              "Best, <br><br>",
                              name_from,
                              "</body></html>")
          } else if (rem_type == "conf_dl") {
            # CONFERENCE DEADLINE REMINDERS
            rem_text <- str_c("<html><body>",
                              "Hello, <br><br>",
                              "This is an automated reminder that the ", description, " has ",
                              case_when(str_detect(str_to_lower(dead_type), "abstract") ~ "an abstract",
                                        str_detect(str_to_lower(dead_type), "paper") ~ "a paper"),
                              " submission deadline coming up on ", deadline, ". <br><br>",
                              "Please remember to submit the ", dead_type, " to ", submission, " as soon as possible. <br><br>",
                              ifelse(exists_not_na("website"), str_c("For more information, please refer to ", website, ". <br><br>"), ""),
                              ifelse(exists_not_na("questions"), str_c("For any questions, please contact ", questions, ". <br><br>"), ""),
                              "Best, <br><br>",
                              name_from,
                              "</body></html>")
          } else if (rem_type == "up_pres") {
            rem_text <- str_c("<html><body>",
                              "Hello, <br><br>",
                              "This is an automated reminder that the ", description, " is going to take place soon. <br><br>",
                              case_when(dead_type == "General presentation reminder" ~
                                          "No further action is needed at this time. <br><br>",
                                        dead_type == "Reminder to submit paper" ~
                                          "Please remember to submit the paper to ", submission, " as soon as possible. <br><br>",
                                        dead_type == "Reminder to submit slides" ~
                                          "Please remember to submit the slides to ", submission, " as soon as possible. <br><br>"),
                              ifelse(exists_not_na("website"), str_c("For more information, please refer to ", website, ". <br><br>"), ""),
                              "Best, <br><br>",
                              name_from,
                              "</body></html>")
            
          } else if (rem_type == "grant_dl") {
            rem_text <- str_c("<html><body>",
                              "Hello, <br><br>",
                              "This is an automated reminder that the ", description,  " has ",
                              case_when(dead_type == "Deliverable reminder" ~ "a deliverable",
                                        dead_type == "Proposal reminder" ~ "a proposal"),
                              "submission deadline coming up on ", deadline, ". <br><br>",
                              ifelse(!is.na(details) & details != "",
                                     str_c("This grant requires the following: <br><br>", details, "<br><br>"), ""),
                              "Please remember to submit the ", str_to_lower(str_remove(dead_type, " reminder")), " to ", submission, " as soon as possible. <br><br>",
                              ifelse(exists_not_na("questions"), str_c("For any questions, please contact ", questions, ". <br><br>"), ""),
                              "Best, <br><br>",
                              name_from,
                              "</body></html>")
          }
          
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
  
  # Save updated Excel
  current_results %<>%
    mutate_at(vars(starts_with("notif_")), ~ifelse(is.na(.), 1, .)) %>% 
    mutate(complete = ifelse(rowSums(across(starts_with("notif_"))) == length(current_freq), 1, complete),
           deadline = str_replace_all(deadline, "-", "_"))
  write_xlsx(current_results, file.path(root_path, "data", rem_file))
}

