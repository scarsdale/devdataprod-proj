---
title       : Sentiment Analysis of Tweets
subtitle    : By Geographic Area and Topic
author      : 
job         : 
framework   : io2012        # {io2012, html5slides, shower, dzslides, ...}
highlighter : highlight.js  # {highlight.js, prettify, highlight}
hitheme     : tomorrow      # 
widgets     : []            # {mathjax, quiz, bootstrap}
mode        : selfcontained # {standalone, draft}
knit        : slidify::knit2slides
---

## Motivation

1. How are residents in a certain area reacting to an event?
* Disasters (e.g. MH370)
* Local politics
* Wins/losses at sporting events (e.g. World Cup matches)
2. Plotting geocoded tweets on a map, classified by sentiment,
gives one view of this.


--- .class #id 

## Sentiment Analysis

##### `sentiment` [package][2]:

* Two algorithms, emotion clustering and score on a positive-negative continuum
* No longer on CRAN, neither are its dependencies

##### `sentiment140` [package][3]:

* Three classes: positive, neutral, negative
* Calls external web service [Sentiment140][4]
* Ultimately used this in the application

```r
library(sentiment) # yes, the package name of sentiment140 is just sentiment
sentiment("This is a really good package!")
```

```
##                             text polarity language
## 1 This is a really good package! positive       en
```

[1]: http://www.inside-r.org/howto/mining-twitter-airline-consumer-sentiment
[2]: https://sites.google.com/site/miningtwitter/questions/sentiment/sentiment
[3]: https://github.com/okugami79/sentiment140
[4]: http://www.sentiment140.com/

--- .class #id 
 
## Mapping

#### Use the `ggmap` package
* `geocode()`: convert natural language name to lat/long

```r
library(ggmap)
geocode("Gary, IN", output="latlona")
```

```
##      lon   lat       address
## 1 -87.35 41.59 gary, in, usa
```
* `get_googlemap()`: download Google map tile of an area as an image
* Can add markers
* `ggmap()`: Plot a map; compatible with `ggplot2`

--- .class #id 

## Limitations

#### Not every tweet carries geo coordinates
* Twitter uses the location stated in a user's profile as a substitute
* But this is often not possible to geocode (jokes, lack of context, &c)

#### Even good sentiment analysis is bad at detecting negation or sarcasm
* Simplistic sentiment analysis is even more problematic
* Quantifying the proportion of such difficult-to-interpret messages
on Twitter would be interesting

### Despite these limitations, this is a good exploratory method
* Find potential patterns for more rigorous investigation
