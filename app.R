#################################################################################
# Small example shinydashboard application to demonstrate an easy way to allow
# use of browser navigation arrows within tabs of an application
# 
# Judy Lewis, PhD
# Vanderbilt Institute for Clinical and Translational Research
# January 7, 2019
#################################################################################

library(shinydashboard)
library(ggplot2)
library(plotly)


shinyUI <- dashboardPage(
  
  dashboardHeader(title = "Browser Navigation in Shiny", titleWidth = 300),
 
  # Sidebar panel
  dashboardSidebar(
    width = 300,
    collapsed = FALSE,
    sidebarMenu(
      id = "tabs",
      menuItem(tagList(span("Introduction")), tabName = "welcome",
               selected = TRUE),
      menuItem(tagList(span("STEP 1: ", class = "text-red", style = "font-weight: bold"),
                       span("Choose dataset")), 
               tabName = "data", icon  = icon("upload")), 
      menuItem(tagList(span("STEP 2: ", class = "text-orange", style = "font-weight: bold"),
                       span("View data")),
               tabName = "view", icon = icon("table")),
      menuItem(tagList(span("STEP 3: ", class = "text-blue", style = "font-weight: bold"),
                       span("Visualize data")), 
               tabName = "interactivePlots", icon = icon("bar-chart")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  
  #main Panel
  dashboardBody(
    tags$head(tags$script("window.onbeforeunload = function() { return true; }")),
    
    tabItems(
      tabItem(tabName = "welcome",
              uiOutput("welcomeUI")
      ),
      tabItem(tabName = "data",
              uiOutput("dataUI"),
              uiOutput("dataDescription")
      ),
      tabItem(tabName = "view",
              uiOutput("viewUI")
      ),      
      tabItem(tabName = "interactivePlots",
              uiOutput("plotUI")
      ),
      tabItem(tabName = "help",
              uiOutput("helpUI")
      )
    )
  )
)

shinyServer <- function(input, output, session){
# code to allow use of browser navigation buttons--------------------------------------
  # Approach: adding current tab name to the URL using the updateQueryString function
  
  # justUpdated indicates if the URL has been updated
  justUpdated <- reactiveVal(FALSE)
  
  # When the tab named in the URL changes, check to see if this new tab name is the same
  # as the tab selected in the sidebar (input$tabs)
  # If this new tab name is NOT the same as the tab selected in the sidebar, this means that
  # the user has clicked on a browser arrow. Update the selected tab (this changes input$tabs) 
  # and also set justUpdated to TRUE.
  # so that when the new value of input$tabs is detected, it is known that the URL is current.
  # If the new tab name is the same as input$tabs, do nothing.
  observeEvent(getQueryString()[["tab"]],{
    req(input$tabs)
    
    newTabRequest <- getQueryString()[["tab"]]
    justUpdated(FALSE)
    if (newTabRequest != input$tabs){
      updateTabItems(session, "tabs", newTabRequest)
      justUpdated(TRUE)
    }
  })
  
  
  # When a new tab is selected (either by the user in the sidebar or by updateTabItems above), 
  # first check to see if the tab name in the URL has already been 
  # updated (in response to the click of a browser button). If so, then change justUpdated back 
  # to FALSE in preparation for the next click and know that the URL is already correct. 
  # Otherwise, if justUpdated is FALSE, this means that the URL needs to be updated with the new 
  # tab name
  observeEvent(input$tabs,{
    if (justUpdated()) {
      justUpdated(FALSE)
      return(NULL)
    }
    updateQueryString(paste0("?tab=",input$tabs), mode = "push")
  })
  

# end of code to allow use of browser navigation buttons----------------------------------
  
  
# UI to generate content (not relevant to navigation)-------------------------------------   
  output$welcomeUI <- renderUI({
    fluidPage(
      box(
        title = tags$b("Demonstration: Using browser navigation arrows in a Shiny app"),
        width = 8,
          tags$p("In a typical Shiny app, clicking the browser", tags$em("back"),"navigation arrow terminates the application, since a Shiny app is technically a single web page."),
          tags$p("This could be frustrating to users because the state of the application is lost, including any uploaded data."),
          tags$p("This small example Shiny application demonstrates an easy way to use reactive values to allow use of the browser navigation arrows to move back and forth between tabs of an application."),
          tags$p("An additional feature which makes use of the javascript onbeforeunload function prevents a user from accidentally exiting an application. This is particularly useful if the user has uploaded a large dataset and/or performed extensive computation in previous steps of the application.")
      )
    )
  })
  
  output$dataUI <- renderUI({
    fluidPage(
      fluidRow(tags$h3(tags$b("Step 1: Choose dataset"))),
      tags$br(),
      fluidRow(
        selectInput("dataChoice", label = "Which dataset would you like to explore?",
                    choices = c("Choose one" = "", "mtcars", "iris", 
                                "trees", "state.x77", "USArrests",
                                "rock", "pressure", "cars"
                                ))
      )
    )
  })
  
  output$dataDescription <- renderUI({
    req(input$dataChoice)
    datasetName <- input$dataChoice
    if (datasetName == "state.x77") datasetName = "state"
    url <- paste0("https://stat.ethz.ch/R-manual/R-devel/library/datasets/html/",
                  datasetName,".html")
      return(
        tagList(
          tags$h4(paste0("Detail about dataset ", input$dataChoice,":")),
          tags$iframe(src = url, style="width:100%;", frameborder="0", id="iframe", height = "500px"),
          tags$h4("Continue to Step 2 to examine the dataset and Step 3 for interactive visualization")
        )
      )
  })
  
  data <- reactive({
    df <- eval(parse(text = input$dataChoice))
    if (input$dataChoice %in% c("state.x77", "USArrests")){
      df <- as.data.frame(df)
      df$State <- factor(rownames(df))
      return(df)
    }
    df <- lapply(df, function(x){
      if (length(unique(x)) < 10){
        return(factor(x, levels = unique(x)))
      } else return(x)
    })
    
    return(as.data.frame(df))
  })

  output$viewUI <- renderUI({
    if (is.null(input$dataChoice) || input$dataChoice == "") {
      return("Please select dataset in Step 1")
    }
    req(data())
    df <- data()
    fluidPage(
      fluidRow(tags$h3(tags$b(paste0("Step 2: View ", input$dataChoice, " dataset")))),
      renderDataTable(df)
    )
  })

  output$selectVar1 <- renderUI({
    req(data())
    df <- data()
    choices1 <- names(which(sapply(df, function(x){!is.factor(x)}))) #variables[!is.factor(variables)]
   return(selectInput("var1", "Select a variable to plot on the x axis", choices = choices1))
  })

  output$selectVar2 <- renderUI({
    req(data())
    req(input$var1)
    df <- data()
    choices2 <- names(which(sapply(df, function(x){!is.factor(x)})))
    choices2 <- choices2[choices2 != input$var1]
    return(selectInput("var2", "Select a variable to plot on the y axis", choices = choices2))
  })
  
  output$selectVar3 <- renderUI({
    req(data())
    req(input$var2)
    df <- data()
    input$var2
    choices3 <- names(which(sapply(df, is.factor)))
    if (rlang::is_empty(choices3)) return(NULL)
    return(selectInput("var3", "Select a variable to use to group data", choices = choices3))
  })
  
  
  p <- eventReactive(input$makePlot,{
    df <- data()
    xVar <- input$var1
    yVar <- input$var2
    if (!any(sapply(df, is.factor))) groupVar <- NULL
    else groupVar <- input$var3
    
    if (is.null(groupVar)) p <- ggplot(df, aes_string(x = xVar, y = yVar))
    else p <- ggplot(df, aes_string(x = xVar, y = yVar, color = groupVar))
    p <- p + 
      geom_point(size = 3) +
      labs(title=paste(yVar, "vs", xVar, "from", input$dataChoice, "dataset"))
    return(ggplotly(p))
  })
  
  output$plotIt <- renderPlotly({
    req(p())
    p()
  })
  
  output$plotButtonUI <- renderUI({
    req(input$var2)
    actionButton("makePlot", "Generate graph")
  })
  
  output$plotUI <- renderUI({
    if (is.null(input$dataChoice) || input$dataChoice == ""){
      return("Please select dataset in Step 1")
    }
    req(data())
    fluidPage(
      fluidRow(tags$h3(tags$b(paste0("Step 3: Visualize ", input$dataChoice, " dataset")))),
      fluidRow(
        column(4, uiOutput("selectVar1")),
        column(4, uiOutput("selectVar2")),
        column(4, uiOutput("selectVar3"))
      ),
      fluidRow(
        column(2, uiOutput("plotButtonUI"))
      ),
      fluidRow(
        plotlyOutput("plotIt")
      )
    )
  })
  
  output$helpUI <- renderUI({
    fluidPage(
      box(
        title = tags$b("Help tab"),
        width = 8,
        tags$h4(
          tags$p("Experiment with choosing different options on Steps 1, 2, and 3 and note that you can navigate back and forth between all five tabs using", tags$em("either"), "the sidebar menu", tags$em("or"), "the browser navigation arrows without changing the state of each tab.")
        )
      )
    )
  })
  # end of UI to generate content ------------------------------------------------------
  

}

shinyApp(ui=shinyUI, server = shinyServer)