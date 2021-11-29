
library(shiny)
library(dplyr)
library(ggplot2)

getMtc <-function(){
  temp <- mtcars
  temp$id <- seq(1,nrow(temp))
  temp$color <- 'white'
  return(temp)
}


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  mtc <- reactiveValues(mtc = getMtc())
  output$plotGG <- renderPlot({
    ggplot(mtc$mtc,aes(wt, mpg))  + geom_point(shape = 21, colour = 'black', fill = mtc$mtc$color, size = 3)
    })

  output$click_data <- renderPrint({
    list(
    click_xy = c(input$clk$x, input$clk$y),
    doble_click_xy = c(input$dclk$x, input$dclk$y),
    hover_xy = c(input$mouse_hover$x, input$mouse_hover$y),
    brush_xy = c(input$mouse_brush$xmin, input$mouse_brush$ymin,
                      input$mouse_brush$xmax, input$mouse_brush$ymax)
    )
  })
  
  #output$
  output$mtc_tbl <- renderTable({
    list(
    brushedPoints(mtc, input$mouse_brush, xvar = 'wt', yvar = 'mpg')
    )
  })
  
  #Brush
  observeEvent(input$mouse_brush,{isolate({
    tdf <- brushedPoints(mtc$mtc, input$mouse_brush, xvar = 'wt', yvar = 'mpg')
    ids <- tdf$id
    print(ids)
    if(!is.null(ids)){
      mtc$mtc$color[ids] <- 'green'
    }
    output$DTtable <- renderDT(
      tdf
    )
    })
  })

  #Click
  observeEvent(input$clk,{isolate({
    tdf <- nearPoints(mtc$mtc, input$clk, xvar = 'wt', yvar = 'mpg')
    ids <- tdf$id
    print(ids)
    if(!is.null(ids)){
      mtc$mtc$color[ids] <- 'green'
    }
    output$DTtable <- renderDT(
      tdf
    )
  })
  })
  
  #Doble Click
  observeEvent(input$dclk,{isolate({
    tdf <- nearPoints(mtc$mtc, input$dclk, xvar = 'wt', yvar = 'mpg')
    ids <- tdf$id
    print(ids)
    if(!is.null(ids)){
      mtc$mtc$color[ids] <- 'white'
      output$DTtable <- renderDT(
        NULL
      )
    }
  })
  })
  
  #Hover
  observeEvent(input$mouse_hover,{isolate({
    tdf <- nearPoints(mtc$mtc, input$mouse_hover, xvar = 'wt', yvar = 'mpg')
    ids <- tdf$id
    print(ids)
    if(length(ids)>0){
      print(length(ids))
      mtc$mtc$color[ids] <- 'grey'
      output$DTtable <- renderDT(
        NULL
      )    
    }

  })
  })
  
})
