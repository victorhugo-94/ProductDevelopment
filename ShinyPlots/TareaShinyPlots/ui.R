library(shiny)
library(DT)

shinyUI(fluidPage(
    titlePanel("Interacciones del usuario con graficas"),
      mainPanel('Interacciones con Plots',
               plotOutput("plotGG",
                          click = 'clk',
                          dblclick = 'dclk',
                          hover = 'mouse_hover',
                          brush = 'mouse_brush'),
               textOutput("tString"),
               #verbatimTextOutput("click_data"),
               DTOutput('DTtable')
               #tableOutput('mtc_tbl')
               #dataTableOutput('mtc_tbl')
               )
    )
)
