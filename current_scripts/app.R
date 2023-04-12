library(shiny)
library(googlesheets4)
library(gargle)
library(shinyvalidate)

pacman::p_load(here, tidyverse, magrittr, tabulator,
               lubridate, gmailr, googlesheets4, 
               htmltools, this.path)
options(gargle_oauth_email = TRUE)

# Useful links:
# shinyvalidate: https://rstudio.github.io/shinyvalidate/articles/shinyvalidate.html


# Define function to check emails
check_emails <- function(entry) {
  email_split <- entry %>% 
    str_split(", ") %>% 
    .[[1]]
  check <- sapply(email_split, function(x) grepl("^\\s*[A-Z0-9._%&'*+`/=?^{}~-]+@[A-Z0-9.-]+\\.[A-Z0-9]{2,}\\s*$", x, ignore.case = TRUE)) %>% sum()
  length_emails <- length(email_split)
  return(check == length_emails)
}
# Define function to check numbers
check_integers <- function(entry) {
  num_split <- entry %>% 
    str_split(",") %>% 
    .[[1]] %>% 
    trimws()
  check <- all(sapply(num_split, function(x) {
    is.integer(as.integer(x))
  }))
  return(check)
}
# Define the ID of the Google Sheet to write data to
sheet_id <- "15ky49_HjBa1vklrhnlnrnufXRlAMl1_wwQzLZ6LvzQg"


# 
# # Set up authentication with Google Sheets API
# options(googleAuthR.scopes.selected = "https://www.googleapis.com/auth/spreadsheets")
# creds <- gargle::Auth()$get_token()
# gs4_auth(token = creds)

gs4_auth(email = "academic.remindr@gmail.com",
         path = "63580478480-09l4ejfegf45g4hbvfr6dkr889jqcqmk.apps.googleusercontent.com")

# (1.2): Import new and previous responses.
all_parameters <- read_sheet("https://docs.google.com/spreadsheets/d/15ky49_HjBa1vklrhnlnrnufXRlAMl1_wwQzLZ6LvzQg/edit?usp=sharing")



#######
ui <- fluidPage(
  
  # Insert break
  br(),
  
  # Application title and logo
  tags$div(
    # Align text left
    style = "text-align:left;",
    
    # Logo
    tags$img(src = "https://raw.githubusercontent.com/clandinq/remindr/main/pictures/logo.png", 
             align = "center", height = "100", width = "100"),
    
    # remindR title
    tags$h2("remindR", align = "left"),
    
  ),
  br(),
  
  # Two tabs
  # titlePanel("My Shiny App"),
  tabsetPanel(
    tabPanel("Sign up",
             
             # Instructions
             tags$h4("Please sign up below.", align = "left"),
             # contents of first tab go here
             # ##############
             # # Block with fields
             # tags$div(
             #   style = "display: flex; justify-content: center; align-items: center;",
             tags$div(
               style = "max-width: 1200px; width: 100%; text-align: left;",
               
               # User Name input
               textInput("user_name", "Username (5-10 characters):", placeholder = "Max 5 characters"),
               
               # Project Name input
               textInput("proj_name", "Project name (5-10 characters, no spaces or special characters):", placeholder = "No spaces or special characters"),
               
               # future conference reminders inputs
               checkboxInput("fut_conf_activate", "Activate future conference reminders?"),
               conditionalPanel(
                 condition = "input.fut_conf_activate == true",
                 textInput("fut_conf_emails", "Emails for future conference reminders (comma-separated, e.g. ''hi@gmail.com, bye@hotmail.com''):"),
                 textInput("fut_conf_freq", "Frequency of future conference reminders (in days, comma-separated, e.g. ''7, 14, 21''):", value = 7)
               ),
               
               # conference deadline reminders inputs
               checkboxInput("conf_dl_activate", "Activate conference deadline reminders?"),
               conditionalPanel(
                 condition = "input.conf_dl_activate == true",
                 textInput("conf_dl_emails", "Emails for conference deadline reminders (comma-separated, e.g. ''hi@gmail.com, bye@hotmail.com''):"),
                 textInput("conf_dl_freq", "Frequency of conference deadline reminders (in days, comma-separated, e.g. ''7, 14, 21''):", value = 7)
               ),
               
               # upcoming presentation reminders inputs
               checkboxInput("up_pres_activate", "Activate upcoming presentation reminders?"),
               conditionalPanel(
                 condition = "input.up_pres_activate == true",
                 textInput("up_pres_emails", "Emails for upcoming presentation reminders (comma-separated, e.g. ''hi@gmail.com, bye@hotmail.com''):"),
                 textInput("up_pres_freq", "Frequency of upcoming presentation reminders (in days, comma-separated, e.g. ''7, 14, 21''):", value = 7)
               ),
               
               # grant deadline reminders inputs
               checkboxInput("grant_dl_activate", "Activate grant deadline reminders?"),
               conditionalPanel(
                 condition = "input.grant_dl_activate == true",
                 textInput("grant_dl_emails", "Emails for grant deadline reminders (comma-separated, e.g. ''hi@gmail.com, bye@hotmail.com''):"),
                 textInput("grant_dl_freq", "Frequency of grant deadline reminders (in days, comma-separated, e.g. ''7, 14, 21''):", value = 7)
               ),
               
               # Submit button
               actionButton("submit", "Submit")
             )
    ),
    tabPanel("New reminder",
    ),
    tabPanel("Edit project",
    ),
    tabPanel("Edit reminders",
    )
  )
)



server <- function(input, output, session) {
  
  # Shinyvalidate
  iv <- InputValidator$new()
  
  # Validate user name input (must be between 5 and 10 characters). Wait for typing to stop before validating. Perform validation with shinyvalidate package.
  iv$add_rule("user_name", sv_required())
  iv$add_rule("user_name", ~ if (nchar(.) > 10) "Username must be less than 10 characters")
  iv$add_rule("user_name", ~ if (nchar(.) < 5) "Username must be more than 5 characters")
  
  # Validate that user name input is not currently used in all_parameters. Perform validation with shinyvalidate package.
  iv$add_rule("user_name", ~ if (input$user_name %in% all_parameters$user_name) "Username already exists")
  
  # Validate project name input (must be between 5 and 10 characters, with only letters, numbers and underscores). Perform validation with shinyvalidate package.
  iv$add_rule("proj_name", sv_required())
  iv$add_rule("proj_name", ~ if (nchar(.) > 10) "Project name must be less than 10 characters")
  iv$add_rule("proj_name", ~ if (nchar(.) < 5) "Project name must be more than 5 characters")
  iv$add_rule("proj_name", ~ if (!grepl("^[A-Za-z0-9_]*$", .)) "Project name must only contain letters, numbers and underscores")
  
  # Validate email inputs (check that each email in commma separated list is a valid email address, with only commas separating emails). Perform validation with shinyvalidate package.
  # future conference reminders
  iv$add_rule("fut_conf_emails", sv_required())
  iv$add_rule("fut_conf_emails", ~ if (!check_emails(.)) "Not a valid email address/addresses")
  iv$add_rule("fut_conf_freq", sv_required())
  iv$add_rule("fut_conf_freq", ~ if (!check_integers(.)) "Not a valid integer/integers")
  
  # conference deadline reminders
  iv$add_rule("conf_dl_emails", sv_required())
  iv$add_rule("conf_dl_emails", ~ if (!check_emails(.)) "Not a valid email address/addresses")
  iv$add_rule("conf_dl_freq", sv_required())
  iv$add_rule("conf_dl_freq", ~ if (!check_integers(.)) "Not a valid integer/integers")
  
  # upcoming presentation reminders
  iv$add_rule("up_pres_emails", sv_required())
  iv$add_rule("up_pres_emails", ~ if (!check_emails(.)) "Not a valid email address/addresses")
  iv$add_rule("up_pres_freq", sv_required())
  iv$add_rule("up_pres_freq", ~ if (!check_integers(.)) "Not a valid integer/integers")
  
  # grant deadline reminders
  iv$add_rule("grant_dl_emails", sv_required())
  iv$add_rule("grant_dl_emails", ~ if (!check_emails(.)) "Not a valid email address/addresses")
  iv$add_rule("grant_dl_freq", sv_required())
  iv$add_rule("grant_dl_freq", ~ if (!check_integers(.)) "Not a valid integer/integers")
  
  iv$enable()
  
  # Submit button
  observeEvent(input$submit, {
    # Create a named list of input values
    new_user_data <- tibble(
      user_name = input$user_name,
      proj_name = input$proj_name,
      fut_conf_activate = input$fut_conf_activate,
      fut_conf_emails = if (input$fut_conf_activate) input$fut_conf_emails else "",
      fut_conf_frequency = if (input$fut_conf_activate) input$fut_conf_freq else "",
      conf_dl_activate = input$conf_dl_activate,
      conf_dl_emails = if (input$conf_dl_activate) input$conf_dl_emails else "",
      conf_dl_frequency = if (input$conf_dl_activate) input$conf_dl_freq else "",
      up_pres_activate = input$up_pres_activate,
      up_pres_emails = if (input$up_pres_activate) input$up_pres_emails else "",
      up_pres_frequency = if (input$up_pres_activate) input$up_pres_freq else "",
      grant_dl_activate = input$grant_dl_activate,
      grant_dl_emails = if (input$grant_dl_activate) input$grant_dl_emails else "",
      grant_dl_freq = if (input$grant_dl_activate) input$grant_dl_freq else ""
    )
    
    
    # Check if user already exists in the Google Sheet
    if (input$user_name %in% all_parameters$user_name) {
      showModal(modalDialog(
        title = "Error",
        "Username already exists! Please choose a new username.",
        easyClose = TRUE
      ))
    } else {
      # Add the new user data to the Google Sheet
      all_parameters %>% 
        bind_rows(new_user_data) %>% 
        sheet_write(ss = sheet_id,
                    sheet = "Sheet1")
      
      # Show a confirmation message
      showModal(modalDialog(
        title = "Form submitted",
        "Thank you for signing up!",
        easyClose = TRUE
      ))
    }
  })
}


shinyApp(ui, server)
