library(shiny)
library(shinyIncubator)
shinyUI(fluidPage(
    progressInit(),
    headerPanel("Tweet Sentiment Analysis by Area"),
    fluidRow(
        column(4,
               p(paste0("Enter a search term and a location, ",
                        "then press Go to see the sentiment ",
                        "(positive, neutral, or negative) of tweets ",
                        "on that topic near that area.")),
               p(paste0("Note that Twitter might find tweets by users ",
                        "whose location in their profile is near ",
                        "the requested location, in addition to tweets ",
                        "geocoded with specific coordinates.")),
               p(paste0("In the map, red markers show negative tweets,",
                        "green markers positive tweets,",
                        "and grey neutral."))),
        column(4, wellPanel(
            textInput("searchterm", label="Topic", value="#worldcup"),
            textInput("geoname",
                      label="Location",
                      value="Rio de Janeiro, Brazil"),
            actionButton("update", "Go"))
        ),
        column(4,
               p("Sentiment analysis performed by the Sentiment140 API."),
               p(a(href="http://www.sentiment140.com",
                   "http://www.sentiment140.com")))
    ),
    fluidRow(
        column(4, plotOutput("map")),
        column(4, tableOutput("summary")),
        column(4, tableOutput("sampling")))
))
