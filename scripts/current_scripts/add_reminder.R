pacman::p_load(tidyverse, shiny, shinyWidgets, shinyTime, shinyvalidate,
               googlesheets4,
               magrittr, readxl, lubridate)
# Help me update this R shiny app.
# Please change the field up_pres_desc to a drop-down menu in which the choices come from the dataset titled "conference_deadline_data" and variable "description" when variable "complete" equals 1. 
# Also allow blank responses. You don't have to show all of the code, just the sections in UI and SERVER that need to be updated.


conference_deadline_data <- read_excel("/Users/cesarlandin/Dropbox/iZettle_fee/reminders/rem_conference_deadlines.xlsx")


# Define the UI
ui <- fluidPage(
  titlePanel("Conference Reminder App"),
  # sidebarLayout(
  # sidebarPanel(
  tags$div(
    style = "max-width: 800px; width: 100%; text-align: left;",
    selectInput("rem_type", "Select conference type", 
                choices = c("Future conference reminders", 
                            "Conference deadlines", 
                            "Reminders for upcoming presentations", 
                            "Grant deadlines")),
    # FUTURE CONFERENCE REMINDERS
    conditionalPanel(
      condition = "input.rem_type == 'Future conference reminders'",
      dateInput("fut_conf_deadline", "Estimated date of conference", 
                format = "yyyy_mm_dd"),
      textInput("fut_conf_desc", "Conference description"),
      textInput("fut_conf_web", "Conference website"),
    ),
    # CONFERENCE DEADLINES
    conditionalPanel(
      condition = "input.rem_type == 'Conference deadlines'",
      fluidRow(
        column(
          width = 6,
          h3("Conference details"),
          textInput("conf_dl_desc", "Conference name"),
          dateInput("conf_dl_sdate", "Start date", format = "yyyy_mm_dd"),
          dateInput("conf_dl_edate", "End date", format = "yyyy_mm_dd"),
          textInput("conf_dl_loc", "Location"),
          textInput("conf_dl_web", "Conference website"),
          textInput("conf_dl_ques", "Contact email (e.g. 'John Smith at js@uni.edu')"),
          downloadButton("download", "Download calendar event")
        ),
        column(
          width = 6,
          h3("Submission details"),
          textInput("conf_dl_sub", "Submission link or email"),
          dateInput("conf_dl_deadline", "Submission deadline", 
                    format = "yyyy_mm_dd"),
          timeInput("conf_dl_time", "Deadline time (optional, defaults to 11:59 PM)", 
                    value = strptime("23:59:59", "%T"), seconds = FALSE),
          dateInput("conf_dl_notif", "Notification date (optional, delete if unknown)", 
                    format = "yyyy_mm_dd", value = NULL),
          selectInput("conf_dl_dead_type", "Abstract or paper submission?", 
                      choices = c("Abstract", "Paper"))
        )
      )
    ),
    # REMINDERS FOR UPCOMING PRESENTATIONS
    conditionalPanel(
      condition = "input.rem_type == 'Reminders for upcoming presentations'",
      selectInput("up_dead_type", "What type of reminder do you want?", 
                  choices = c("General presentation reminder", "Reminder to submit slides", "Reminder to submit paper")),
      conditionalPanel(
        condition = "input.up_dead_type == 'General presentation reminder'",
        dateInput("up_pres_deadline", "Presentation date", format = "yyyy_mm_dd")
      ),
      conditionalPanel(
        condition = "input.up_dead_type == 'Reminder to submit paper' || input.up_dead_type == 'Reminder to submit slides'",
        dateInput("up_pres_deadline", "Deadline", format = "yyyy_mm_dd")
      ),
      selectizeInput("up_pres_desc", "Conference description", 
                     choices = conference_deadline_data %>% 
                       filter(complete == 1) %>% 
                       pull(description) %>% 
                       sort(),
                     options = list(create = TRUE)),
      conditionalPanel(
        condition = "input.up_dead_type == 'Reminder to submit paper' || input.up_dead_type == 'Reminder to submit slides'",
        textInput("up_pres_sub", "Submission link or email")
      ),
      textInput("up_pres_web", "Conference website"),
    ),
    # GRANT DEADLINES
    conditionalPanel(
      condition = "input.rem_type == 'Grant deadlines'",
      selectInput("grant_dl_dead_type", "What type of reminder do you want?", 
                  choices = c("Deliverable reminder", "Proposal reminder")),
      dateInput("grant_dl_deadline", "Deadline", format = "yyyy_mm_dd"),
      textInput("grant_dl_desc", "Grant description"),
      textInput("grant_dl_details", "Submission details"),
      textInput("grant_dl_ques", "Grant questions"),
      textInput("grant_dl_sub", "Submission link or email"),
    ),
    actionButton("submit", "Submit")
  ),
  mainPanel(
    tableOutput("regTable")
  )
)

# Define the server
server <- function(input, output) {
  
  # Shinyvalidate
  iv <- InputValidator$new()
  
  # Validate upcoming presentation deadlines: deadline, description and link necessary.
  iv$add_rule("up_pres_deadline", sv_required())
  iv$add_rule("up_pres_desc", sv_required())
  iv$add_rule("up_pres_sub", sv_required())
  
  # Validate grant deadlines: deadline, description and link necessary.
  iv$add_rule("grant_dl_deadline", sv_required())
  iv$add_rule("grant_dl_desc", sv_required())
  iv$add_rule("grant_dl_details", sv_required())
  iv$add_rule("grant_dl_sub", sv_required())
  
  # Validate start date in the future (at least today)
  # Validate end date in the future (at least today) and equal or later than start date
  
  iv$enable()
  
  
  # Define reactive variable for storing registration data
  regData <- reactiveValues(data = data.frame())
  
  # Set up calendar event download
  output$download <- downloadHandler(
    filename = function() {
      paste(input$conf_dl_desc, ".ics", sep = "")
    },
    content = function(file) {
      event <- ic_event(
        summary = input$conf_dl_desc,
        start_time = as.character(input$conf_dl_sdate),
        end_time = as.character(input$conf_dl_edate),
        format = calendar::formats$`yyyy-mm-dd`,
        more_properties = TRUE,
        event_properties = c("DESCRIPTION" = input$conf_dl_desc,
                             "LOCATION" = input$conf_dl_loc,
                             "DTSTART;VALUE=DATE" = format(as.Date(input$conf_dl_sdate, "%Y_%m_%d"), "%Y%m%d"),
                             "DTEND;VALUE=DATE" = format(as.Date(input$conf_dl_edate, "%Y_%m_%d") + days(1), "%Y%m%d"))
      )
      ic_write(event, file)
    }
  )
  
  # Define function to add new registration data to the reactive variable
  addData <- function() {
    newData <- data.frame(
      rem_type = input$rem_type,
      deadline = as.character(input$deadline),
      noti = as.character(input$noti),
      desc = input$desc,
      ques = input$ques,
      sub = input$sub,
      dead_type = input$dead_type,
      web = input$web,
      complete = ifelse(input$complete, "yes", "no")
    )
    regData$data <- rbind(regData$data, newData)
  }
}
shinyApp(ui, server)
