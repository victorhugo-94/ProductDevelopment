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
library(pdftools)
library(tidyverse)
library(shinyWidgets)
#----Funciones----
#-----ReadPdf-----
read_pdf <- function(path){
   text = pdf_text(pdf = path)
   date <- str_extract_all(text[1],"([0-9]{2})/([0-9]{2})/([0-9]{4})")
   date <- as.Date(date[[1]], "%d/%m/%Y")
   date <- format(date, "%y/%m/%d")
   ext <- str_match(text[1], "\\(MWh\\)\n\n((?s).*)\nTotal")
   temp <- str_replace_all(ext[2], "\n", "|")
   res <- str_extract_all(temp, "([A-Z0-9\\s\\.]+)|")[[1]]
   df1 <- data.frame(matrix(ncol = 4, nrow = 0))
   for(i in res){
      name <- trimws(str_extract(i, '([A-Z\\s]+)'))
      values <- array(as.numeric(str_extract_all(i, '([0-9\\.]+)')[[1]]))
      container = c(name, values)
      if(!is.na(container[1])){
         df1 <- rbind(df1, container)    
      }
   }
   colnames(df1) <- c("Planta",
                      "Limitacion_MW",
                      "TiempoLimitacion_Hrs",
                      "Energia")
   #Lectura de limitaciones por causa
   ext <- str_match(text[4], "12\\n\\n((?s).*)Total")
   temp <- str_replace_all(ext[2], "\n", "|")
   res <- str_extract_all(temp, "([A-Z0-9\\s]+)|")[[1]]
   df2 <- data.frame(matrix(ncol = 13, nrow = 0))
   for(i in res){
      name <- trimws(str_extract(i, '([A-Z\\s]+)'))
      values <- array(as.numeric(str_extract_all(i, '([0-9]+)')[[1]]))
      container = c(name, values)
      if(!is.na(container[1])){
         df2 <- rbind(df2, container)
      }
   }
   colnames(df2) <- c("Planta",
                      "c1","c2","c3","c4",
                      "c5","c6","c7","c8",
                      "c9","c10","c11","c12"
   )  
   newdf <- merge(df1,df2,by = c("Planta"))
   newdf <- cbind(Fecha = date, newdf)
   lResult <- list('Fecha' = date, 'Data' = newdf)
   return(lResult)
}

#----Funcion de lectura de BD---
getBdData <- function(){
   drv <- dbDriver("MySQL")
   con <- dbConnect(drv,
                    dbname = 'streamlit',
                    host = '34.125.174.19',
                    port = 3306,
                    user = 'admin',
                    password = 'password'
   )
   resDf <- dbGetQuery(con, "Select * from limitaciones where delState = 'No'")
   dbDisconnect(con)
   return(resDf)
}
# ---- Cargar datos ----
data2<- data.frame(read_xlsx("Ubicacion plantas solares y eolicas.xlsx"))
#df <- data.frame(read_xlsx("Limitaciones.xlsx"))
df <- getBdData()
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
            tabPanel("Actualizacion de la base de datos",
               textInput("url", "Ingrese URL para carga", value = ""),
               actionButton("button1", "Carga"),
               DT::dataTableOutput("newData")
            )
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
   #----Carga de datos----
   observeEvent(input$button1,{
      con <- dbConnect(drv,
                       dbname = 'streamlit',
                       host = '34.125.174.19',
                       port = 3306,
                       user = 'admin',
                       password = 'password'
      )
      temp <- tempfile(fileext = ".pdf")
      download.file(input$url, temp, mode = "wb")
      resList <- read_pdf(temp)
      query <- "update limitaciones set delState ='Si' where Fecha = "
      query <- paste0(query,"'", as.character(resList$Fecha), "';")
      dbSendQuery(con, query)
      dbWriteTable(con, value = resList$Data, name = "limitaciones", append = TRUE,row.names = F)
      dbDisconnect(con)
      output$newData <- renderDT(
         resList$Data
      )
   })
   
   

}

shinyApp(ui, server)

#install.packages( "shinyWidgets",repos="http://cran.us.r-project.org")