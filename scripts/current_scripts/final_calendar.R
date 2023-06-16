pacman::p_load(shiny, calendar, lubridate)

# Calendar documentation:
# https://www.rdocumentation.org/packages/calendar/versions/0.0.1
# https://github.com/ATFutures/calendar/blob/master/R/ic_event.R

ui <- fluidPage(
  textInput("title", "Event Title"),
  textInput("description", "Event Description"),
  textInput("location", "Event Location"),
  dateInput("start_date", "Start date"),
  dateInput("end_date", "End date"),
  downloadButton("download", "Download .ics")
)

server <- function(input, output) {
  output$download <- downloadHandler(
    filename = function() {
      paste(input$title, ".ics", sep = "")
    },
    content = function(file) {
      event <- ic_event(
        summary = input$title,
        start_time = as.character(input$start_date),
        end_time = as.character(input$start_date),
        format = calendar::formats$`yyyy-mm-dd`,
        more_properties = TRUE,
        event_properties = c("DESCRIPTION" = input$description,
                             "LOCATION" = input$location,
                             "DTSTART;VALUE=DATE" = format(as.Date(input$start_date), "%Y%m%d"),
                             "DTEND;VALUE=DATE" = format(as.Date(input$end_date) + days(1), "%Y%m%d"))
      )
      ic_write(event, file)
    }
  )
}

# Next step for tomorrow: fill out calendar from conference data! And have button "Download calendar"
# Then: immediately finish time and timezone support

shinyApp(ui, server)
