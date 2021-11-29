

library(shiny)


shinyUI(fluidPage(


    titlePanel("Interacciones del usuario con graficas"),
    
    tabsetPanel(
      tabPanel('Graficas Shiny',
               h1('Graficas en shiny'),
               plotOutput('grafica_base_r'),
               plotOutput('Grafica_ggplot')
               ),
      
      tabPanel('Interacciones con Plots',
               plotOutput("plot_click_option",
                          click = 'clk',
                          dblclick = 'dclk',
                          hover = 'mouse_hover',
                          brush = 'mouse_brush'),
               verbatimTextOutput("click_data"),
               dataTableOutput('mtcars_tbl')
               
               )
    )
    
    #Investigar funcion points
    
    
    

))
