#' EDA UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_EDA_ui <- function(id){
  ns <- NS(id)
  tagList(
    sidebarLayout(
      sidebarPanel( width=3,
        h3("Exploratory Plots"),
        radioButtons(ns("which_data"),"Select data", choices=c("current","new"),selected="current"),
        actionButton(ns("replace_data"),"Replace current with new"),
        sliderInput(ns("plotsize"),
                    label   = 'Plot size',
                    value = 2,
                    min = 1, max=6, step=1
        )
      ),
      mainPanel( width = 9,
        tabsetPanel(
          tabPanel("Summary",
                   verbatimTextOutput(ns("print_skim"))
                   #textOutput(ns("print_skim"))
                   #htmlOutput(ns("print_skim"))
                   ),
          tabPanel("Plot count",
                   plotOutput(ns("plot_responses"))
                   ),
          tabPanel("Plot Proportion",
                   plotOutput(ns("plot_responses_pct"))
                   ),
          tabPanel("PCA",
                   uiOutput(ns("plot_pca")),
                   verbatimTextOutput(ns("print_summary_pca")),
          ),
          tabPanel("PCA Scree",
                   selectInput(ns("scree_which"),"Which scree plot",
                               choices = c("Standard deviation","Proportion of Variance","Cumulative Proportion","Eigen Values"),
                               selected = "Eigen Values"),
                   plotOutput(ns("plot_pca_scree")),
                   dataTableOutput(ns("table_components"))
          ),
          tabPanel("Correlation Plot",
                   uiOutput(ns("plot_pairs"))
                   ),
          tabPanel("tSNE",
                   sliderInput(ns("perplexity"),"Perplexity",
                               min = 1, max=100,value=50,step=5),
                   sliderInput(ns("theta"),"Theta",
                               min = 0.0, max=1.0,value=0.5,step=0.1),
                   sliderInput(ns("exag"),"Exagerration",
                               min = 0.0, max=50,value=12,step=1),
                   uiOutput(ns("plot_tsne"))
          )
          
        )
      )
    )
 
  )
}
    
#' EDA Server Functions
#'
#' @noRd 
mod_EDA_server <- function(id){
  moduleServer( id, function(input, output, session){
    ns <- session$ns
    
    # Logging
    shinyEventLogger::set_logging_session()
    
    shinyEventLogger::log_message("mod_boot_kmeans_server")
    
    DATA <- reactiveVal(data_df)
    
    ##### Plot Size in reactive
    
    plotsize <- reactive({
      req(input$plotsize)
      as.numeric(input$plotsize)
    })
    
    plotHeight <- reactive(480 * plotsize())      
    
    #####
    

    output$plot_responses <- renderPlot({
      plot_responses(DATA())
    })
    
    output$plot_responses_pct <- renderPlot({
        plot_responses_pct(DATA())
    })

    ## Plot PCA
    
    output$plot_pca_raw <- renderPlot({
      plot_pca(DATA())
    })
    
    output$plot_pca <- renderUI({
      plotOutput(ns("plot_pca_raw"), height = plotHeight())
    })
    
    #####
    
    ## Plot tsne
    
    output$plot_tsne_raw <- renderPlot({
        plot_tsne(data=DATA(),
                  perp=input$perplexity,
                  theta=input$theta,
                  exag=input$exag)
    })
    
    output$plot_tsne <- renderUI({
      plotOutput(ns("plot_tsne_raw"), height = plotHeight())
    })
    
    #####
    
    output$print_skim <- shiny::renderPrint({
      shinyEventLogger::log_message("save DATA to params$data")
        params$data <<- DATA()
      shinyEventLogger::log_message("output$print_skim")
        skimr::skim(DATA())
    },width=120)
    
    output$print_summary_pca <- shiny::renderPrint({
        print_summary_pca(DATA())
    })
    
    observeEvent(input$replace_data, {
      shinyEventLogger::log_message("input$replace_data\n BEFORE data_df:",nrow(data_df),"rows  new_data_df:", nrow(new_data_df)," rows")
      data_df <<- new_data_df
      DATA <- reactiveVal(data_df)
      shinyEventLogger::log_message("AFTER  data_df:",nrow(data_df),"rows  new_data_df:", nrow(new_data_df)," rows")
      
    })
    
    observeEvent(input$which_data, {
      if(input$which_data == "current"){
        DATA(data_df)
      } else {
        DATA(new_data_df)
      }
    })
    
    output$plot_pca_scree <- renderPlot({
      plot_pca_scree(DATA(),which=input$scree_which)
    })
    
    output$table_components <- renderDataTable({
      table_components(DATA())
    })
    
    ## Plot correlation pairs
    
    output$plot_pairs_raw <- renderPlot({
      plot_pairs(DATA())
    })
    
    output$plot_pairs <- renderUI({
      plotOutput(ns("plot_pairs_raw"), height = plotHeight())
    })
    
    ####
    
  })
}
    
## To be copied in the UI
# mod_EDA_ui("EDA_ui_1")
    
## To be copied in the server
# mod_EDA_server("EDA_ui_1")
