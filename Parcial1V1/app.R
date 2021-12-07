library(shiny)
library(leaflet)
library(readxl)
library(DT)
library(lubridate)
library(dplyr)
library(ggplot2)
library(forcats)
library(ggdist)
library(plotly)
library(RMySQL)
library(shinyWidgets)
#----Funciones----
#----Funcion de lectura de BD---
# getBdData <- function(){
#    drv <- dbDriver("MySQL")
#    con <- dbConnect(drv,
#                     dbname = 'streamlit',
#                     host = '34.125.174.19',
#                     port = 3306,
#                     user = 'admin',
#                     password = 'password'
#    )
#    resDf <- dbGetQuery(con, "Select * from limitaciones where delState = 'No'")
#    dbDisconnect(con)
#    return(resDf)
# }
# ---- Cargar datos ----
data2<- data.frame(read_xlsx("Ubicacion plantas solares y eolicas.xlsx"))
df <- data.frame(read_xlsx("Limitaciones.xlsx"))
#df <- getBdData()
df$Fecha <- as.Date(as.character(df$Fecha), format = "%y/%m/%d")
df <- df[,2:ncol(df)]
minimo <- min(df$Energia, na.rm = TRUE)
maximo <- max(df$Energia, na.rm = TRUE)
df_group_init <- df %>% replace(is.na(.),0) %>% group_by(Planta) %>% summarise(Energia=sum(Energia))


# ---- Interfaz de usuario ----
ui <- fluidPage(
   sidebarLayout(
      sidebarPanel(
         titlePanel(title = "Filtros"),
         sliderInput(
            "slider1",
            "Seleccione nivel de Energia",
            min = minimo,
            max = maximo,
            value = c(minimo, maximo)
         ),
         numericRangeInput(
            "numericRange1",
            "Ingrese rango",
            value = c(minimo,maximo),
            width = NULL,
            separator = " a ",
            min = minimo,
            max = maximo,
            step = 100
         ),
         selectInput(
            "Planta",
            "Seleccione una planta:",
            choices = c(unique(df$Planta)),
            multiple = TRUE
         ),
         dateRangeInput(
            "date_range",
            "Seleccione un rango de fechas:",
            min = min(df$Fecha),
            max = today(),
            start = min(df$Fecha),
            end = today(),
            language = "es",
            weekstart = 1,
            separator = "a"
         ),
         downloadButton("descargar_datos",
            "Descargar datos"
         ),
         width = "2"
      ),
      mainPanel(
         tabsetPanel(id = "tsp",
            tabPanel("Mapa",
            titlePanel (title="Ubicacion de plantas solares"),
            leafletOutput("map",height = 800)
            ),
            navbarMenu("Tablas",
            tabPanel("Completa",
            titlePanel (title="Tabla de datos"),
            DT::dataTableOutput("table")
            ),
            tabPanel("Sumarizada",
            titlePanel (title="Tabla de datos sumarizada"),
            DT::dataTableOutput("table_sumarizada")
            )
            ),
            navbarMenu("Graficas",
            tabPanel("Barras",
            titlePanel (title="Graficas de barras"),
            plotlyOutput("plot"),
            plotlyOutput("barplot")
            ),
            tabPanel("Boxplot",
            titlePanel (title="Graficas de boxplot"),
            plotOutput("bplot2")
            ),
            tabPanel("Lineas",
            titlePanel (title="Graficas de lineas"),
            plotlyOutput("lplot2"),
            plotlyOutput("scatterplot2")
            )
            ),
            # tabPanel("Actualizacion de la base de datos",
            # titlePanel (title="Actualizacion de la base de datos"),
            # fileInput('file_input', 'upload file ( . pdf format only)', accept = c('.pdf')), 
            # DT::dataTableOutput("newdata")
            # )
         ),
         width = "10"
      )
   )
)

# ---- Servidor de aplicaciones ----
server <- function(input, output, session) {
   # ---- Variables globales ----
   data <- reactiveValues(df=df)
   df_filtered <- reactiveValues(df=data.frame())
   df_grouped <- reactiveValues(df= df_group_init)
 
   # ---- Eventos ----
   observe({
      query <- parseQueryString(
         session$clientData$url_search
      )
      if (!is.null(query[['tab']])) {
         updateTabsetPanel(
            session,
            "tsp",
            selected = query[['tab']]
         )
      }
   })
   observeEvent(
      input$slider1, {
         df_filtered$df <- data$df %>%
            filter(Planta %in% input$Planta) %>%
            filter(Energia >= input$slider1[1] & Energia <= input$slider1[2]) %>%
            filter(Fecha >= input$date_range[1] & Fecha <= input$date_range[2])
            df_grouped$df <- df_filtered$df %>%
               group_by(Planta) %>%
               summarise(Energia=sum(Energia))
         updateNumericRangeInput(
            session,
            "numericRange1",
            value = input$slider1
         )
      }
   )
   observeEvent(
      input$Planta,{
         df_filtered$df <- data$df %>%
            filter(Planta %in% input$Planta) %>%
            filter(Energia >= input$slider1[1] & Energia <= input$slider1[2]) %>%
            filter(Fecha >= input$date_range[1] & Fecha <= input$date_range[2])
            df_grouped$df <- df_filtered$df %>%
               group_by(Planta) %>%
               summarise(Energia=sum(Energia))
      }
   )
   observeEvent(
      input$date_range,{
         df_filtered$df <- data$df %>%
            filter(Planta %in% input$Planta) %>%
            filter(Energia >= input$slider1[1] & Energia <= input$slider1[2]) %>%
            filter(Fecha >= input$date_range[1] & Fecha <= input$date_range[2])
            df_grouped$df <- df_filtered$df %>%
               group_by(Planta) %>%
               summarise(Energia=sum(Energia))
      }
   )
   observeEvent(
      input$numericRange1,{
         updateSliderInput(
            session,
            "slider1",
            value = input$numericRange1
         )       
      }
   )


   # ---- Renderizar mapa ----
   output$map <- renderLeaflet({
      df_merge <- merge(df_grouped$df, data2, all = TRUE)
      if(length(input$Planta)==0) {
         df_temp <- df_merge
      }
      else {
         df_temp <- df_merge %>%
         filter(Planta %in% input$Planta)

      }
      df_temp$Label <- with(df_temp, paste(Planta,"</b> </br>", Energia, " kWh", sep=""))

    leaflet(df_temp) %>%
      addTiles() %>%
      addCircles(lng =~Longitud, lat =~Latitud,
         radius = ~Energia/sum(Energia)*50000, color = "red", popup = ~Label
      )
  })
   # ---- Renderizar tablas ----
   output$table <- renderDataTable(
      df_filtered$df
   )
   output$table_sumarizada <- renderDataTable(
      df_grouped$df
   )
   # ---- Render graficas ----
   output$plot <- renderPlotly({
      df_grouped$df %>%
      mutate(Planta = fct_reorder(Planta,desc(Energia))) %>%
      plot_ly(x = ~Energia,
         y = ~Planta,
         name = "Plotly", type = "bar"
      )
   })
   output$bplot2 <- renderPlot({
      ggplot(df_filtered$df[which(df_filtered$df$Energia>0),], aes(x = Planta, y = Energia , fill = Planta)) +
         ggdist::stat_halfeye(
            adjust = .5, 
            width = .6, 
            .width = 0, 
            justification = -.2, 
            point_colour = NA
         ) +
      geom_boxplot(width=0.2/length(unique(df_filtered$df$Planta))) 
   })
   output$lplot2 <- renderPlotly({
      df_temp_fecha <- df_filtered$df %>%
         group_by(Fecha) %>%
         summarise(Energia = sum(Energia))
      plot_ly(df_temp_fecha,
      x= ~Fecha,
      y= ~Energia,
      type = "scatter",
      mode = "lines",
      marker = list(size = 2, color = "ligthblue")
      )
   })
   output$scatterplot2 <- renderPlotly({
      df_temp_fecha <- df_filtered$df %>%
         group_by(Fecha) %>%
         summarise(Energia = sum(Energia))
      plot_ly(df_temp_fecha,
      x= ~Fecha,
      y= ~Energia,
      type = "scatter",
      mode = "bar",
      marker = list(size = 5, color = "ligthblue")
      )
   })
   # ---- Descargar datos ----
   output$descargar_datos <- downloadHandler(
    filename = function(){
      paste('data-',Sys.Date(),'.csv',sep='')
      },
      
      content = function(file){
        readr::write_csv(df_filtered$df,file)
      }
    
  )
   

}

shinyApp(ui, server)

#install.packages( "shinyWidgets",repos="http://cran.us.r-project.org")