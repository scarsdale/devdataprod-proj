library(shiny)
library(shinyIncubator)
library(ggmap)
library(memoise)
library(sentiment)
library(twitteR)

load("credential")
registerTwitterOAuth(twitCred)

# get lat/lon using Google geocode API
# memoize to minimize the number of requests to the API
getgeo <- memoise(function(geoname) {
    suppressMessages(geocode(geoname, output="latlona"))
})
# format coordinates and radius for Twitter search API
fmt.twitrgeo <- function(geo, radius) {
    paste(geo["lat"], geo["lon"], paste0(radius, "km"), sep=",")
}
# get <= 50 tweets geocoded within 10km of given coordinates
gettweets <- function(searchterm, geo) {
    suppressMessages(searchTwitter(searchterm,
                                   n=50,
                                   geocode=fmt.twitrgeo(geo, 10),
                                   lang="en"))
}
# reformat coordinates for Google static map API
fmt.gmapgeo <- function(geo) { c(geo[1, "lon"], geo[1, "lat"]) }
# take a data frame of lat, lon, and color; convert that into a string
# to pass into the Google static maps API and produce colored markers
fmt.markers <- function(markerdf) {
    markerparams <- lapply(unique(markerdf$color), function(color) {
        markers <- markerdf[markerdf$color == color, c("lat", "lon")]
        locs <- Map(function(lat, lon) { paste(lat, lon, sep=",") },
            markers$lat,
            markers$lon)
        Reduce(function(acc, loc) { paste(acc, loc, sep="|") },
               locs,
               paste("color", color, sep=":"))
    })
    ret <- do.call(function(...) { paste(..., sep="&markers=") }, markerparams)
    ret
}
# call Google static map API to get a map image
# with specified center and markers; markers should be output of fmt.markers()
getmap <- function(geo, markers) {
    suppressMessages(get_googlemap(fmt.gmapgeo(geo),
                                   zoom=11,
                                   maptype="hybrid",
                                   markers=markers))
}
# call sentiment140 API to run sentiment analysis on a tweet
# memoize in case we end up processing the same set of tweets repeatedly
getsentiment <- memoise(function(s) { sentiment(s)$polarity })
# get the coordinates associated with the given users
getusergeo <- function(handles) {
    rawusers <- lookupUsers(handles)
    users <- twListToDF(rawusers)
    geos <- lapply(users$location, getgeo)
    usergeo <- data.frame(screenName=users$screenName,
                          lat=sapply(geos, function(v) { v$lat }),
                          lon=sapply(geos, function(v) { v$lon }))
    data.frame(lat=sapply(handles,
                   function(h) { usergeo[usergeo$screenName == h, "lat"] }),
               lon=sapply(handles,
                   function(h) { usergeo[usergeo$screenName == h, "lon"] }))
}
# get the coordinates associated with the given tweets
# this may be directly in the tweet or it may in the user profile
gettweetgeos <- function(tweets) {
    latlon <- c("latitude", "longitude")
    isnogeo <- function(dat) { !complete.cases(dat[,latlon]) }
    coords <- tweets[,latlon]
    nogeo <- isnogeo(coords)
    fromusers <- getusergeo(tweets[nogeo, "screenName"])
    coords[nogeo, latlon] <- fromusers
    coords
}
# reduce list of status objects to data frame of lat, lon, text, polarity
proctweets <- function(tweets) {
    coords <- gettweetgeos(tweets)
    ret <- data.frame(lat=coords$latitude,
                      lon=coords$longitude,
                      text=tweets$text,
                      polarity=getsentiment(tweets$text))
    ret[complete.cases(ret[,c("lat", "lon")]),]
}
polaritytocolor <- Vectorize(function(polarity) {
    if (polarity == "positive") {
        "green"
    } else if (polarity == "negative") {
        "red"
    } else {
        "grey"
    }
})
shinyServer(
    function(input, output, session) {
        geo <- reactive({
            input$update
            isolate({
                withProgress(session, {
                    setProgress(message="Finding location...")
                    if (nchar(input$geoname) > 0)
                        getgeo(input$geoname)
                    else
                        c(NA, NA)
                })
            })
        })
        rawtweets <- reactive({
            input$update
            isolate({
                withProgress(session, {
                    setProgress(message="Getting tweets...")
                    gettweets(input$searchterm, geo())                    
                })
            })
        })
        getproctweets <- reactive({
            input$update
            isolate({
                withProgress(session, {
                    setProgress(message="Analyzing tweets...")
                    proctweets(twListToDF(rawtweets()))
                })
            })
        })
        output$map <- renderPlot({
            curgeo <- geo()
            if (!any(is.na(curgeo))) {
                tweets <- getproctweets()
                colored <- tweets
                colored$color <- polaritytocolor(tweets$polarity)
                basemap <- getmap(curgeo, fmt.markers(colored))
            } else {
                basemap <- getmap(data.frame(lat=52.9178, lon=-4.0933),
                                  "label:6|52.9178,-4.0933")
            }
            plotmap <- ggmap(basemap)
            print(plotmap)
        }, width=640, height=640)
        output$summary <- renderTable({
            curgeo <- geo()
            if (!any(is.na(curgeo))) {
                tweets <- getproctweets()
                table(tweets$polarity, dnn="Count by Sentiment")
            } else {
                table(numeric())
            }
        })
        output$sampling <- renderTable({
            curgeo <- geo()
            if (!any(is.na(curgeo))) {
                tweets <- getproctweets()
                tweets[sample(seq_along(tweets$text), 5), c("text", "polarity")]
            } else {
                data.frame()
            }
        })
    }
)
