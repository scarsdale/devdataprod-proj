reqURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"
load("apikeys")
twitCred <- OAuthFactory$new(consumerKey=consumerKey,
                             consumerSecret=consumerSecret,
                             requestURL=reqURL,
                             accessURL=accessURL,
                             authURL=authURL)
cred <- twitCred$handshake(cainfo=system.file("CurlSSL",
                                              "cacert.pem",
                                              package="RCurl"))
save("cred", file="credential")
