##########################################################
#
#     HANJO ODENDAAL 
#     hanjo.oden@gmail.com
#     www.daeconomist.com
#     @UbuntR314
#     https://github.com/HanjoStudy
#     
#
#     ██████╗ ███████╗███████╗██╗     ███████╗███╗   ██╗██╗██╗   ██╗███╗   ███╗
#     ██╔══██╗██╔════╝██╔════╝██║     ██╔════╝████╗  ██║██║██║   ██║████╗ ████║
#     ██████╔╝███████╗█████╗  ██║     █████╗  ██╔██╗ ██║██║██║   ██║██╔████╔██║
#     ██╔══██╗╚════██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║██║██║   ██║██║╚██╔╝██║
#     ██║  ██║███████║███████╗███████╗███████╗██║ ╚████║██║╚██████╔╝██║ ╚═╝ ██║
#     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝     ╚═╝
#                                                                                
#     Last update: June 2018
#     
##########################################################

# By the end of the session I want you to be comfortable with
# 
#   * Connecting to RSelenium 
#    - Understand basic docker commands
#   * Be able to construct a scraper that
#    - navigates
#    - scrolls
#    - interacts with DOM
#    - build a scraper framework snippet
#   * Use screenshots

# -------------------------------------
# Why we use RSelenium 
# -------------------------------------

# RSelenium allows you to carry out unit testing and regression testing on your webapps and webpages across a range of browser/OS combinations

# > Selenium makes our task easy as it can scrape complicated webpages with dynamic content
# > "Human-like" behaviour such as clicking and scrolling
# > FINALLY a stable server instance through docker!
# > They joy when you finally get it working!

# Getting the old boy started

# CRAN recently removed `RSelenium` from the repo, thus it is even more difficult to get the your `Selenium` instance up and running in `R`
# We will be using `devtools` to install the necessary dependencies from `github`

devtools::install_github("johndharrison/binman")
devtools::install_github("johndharrison/wdman")
devtools::install_github("ropensci/RSelenium")

# Once you have installed all the packages, remember to load `RSelenium` into your workspace

library(RSelenium)
library(rvest)
library(tidyverse)

# -------------------------------------
# Turning the iginition (docker style)
# -------------------------------------

# RSelenium is notorius for instability and compatibility issues. It is thus amazing that they now have a docker image for headless webdrivers. Running a docker container standardises the build across OS’s and removes many of the issues user may have relating to JAVA/browser version/selenium version

# > Offers improved stability
# > Greater ease in setting up the Selenium server
# > Quick up and down 

# Get your environment setup
# sudo docker pull selenium/standalone-chrome-debug

# Starting your Selenium Server i debug

# docker run --name chrome -d -p 4445:4444 -p 5901:5900 selenium/standalone-chrome-debug:latest
# sudo docker ps

# * `-name` name your container, otherwise docker will ;-)
# * `-d` detached mode
# * `-p` port mapping (external:internal)
# * if on external server: `127.0.0.1:port:port`

# Attach your viewport (TightVNC & Vinagre)
# We can use Virtual Network Computing (VNC) viewers to view what is happening

# Finally - RSelenium is operational
# * Quick overview of the tools you will be using
# * Useful functions written in javascript that I find useful
# * Obsure and fun functions
# * Combine it all into a case study


# -------------------------------------
# Open and navigate
# -------------------------------------

library(RSelenium)

# This command sets up a list of the parameters we are going to send to selenium to kick off
remDr <- remoteDriver(remoteServerAddr = "192.168.99.100",
                      port = 4445L, 
                      browser = "chrome")

# Notice the strange notation? Thats because of Java object.method
remDr$open()

# Use method navigate to drive your browser around
remDr$navigate("http://www.google.com")
remDr$navigate("http://www.bing.com")

# Use methods back and forward to jump between pages
remDr$goBack()
remDr$goForward()

# -------------------------------------
# Using keys and Scrolling
# -------------------------------------

# We can send various keys to the Selenium
RSelenium:::selKeys %>% names()

# Note the notation of the command object$method(list = "command)
remDr$sendKeysToActiveElement(list(key = "page_down"))
remDr$sendKeysToActiveElement(list(key = "page_up"))

# We also send Javascript to the page - this becomes important if you want to know how far down you have scrolled...
remDr$executeScript("return window.scrollY", args = list(1))
remDr$executeScript("return document.body.scrollHeight", args = list(1))

remDr$executeScript("return window.innerHeight", args = list(1))
remDr$executeScript("return window.innerWidth", args = list(1))

remDr$sendKeysToActiveElement(list(key = "home"))
remDr$sendKeysToActiveElement(list(key = "end"))

# -------------------------------------
# Interacting with the DOM
# -------------------------------------

# The DOM stands for the Document Object Model. It is a cross-platform and language-independent convention for representing and interacting with objects in HTML, XHTML and XML documents. To get the whole DOM:
  
remDr$getPageSource() %>% .[[1]] %>% read_html()

# To interact with the DOM, we will use the `findElement` method:
  
# > Search by id, class, selector, xpath

remDr$navigate("http://www.google.com/")

# This is equivalent to html_nodes
webElem <- remDr$findElement(using = 'class', "gsfi")

webElem$highlightElement()
 
# Having identified the element we want to interact with, we have a couple of methods that we can apply to the object:

webElem$clickElement()
webElem$click(2)

# Cannot interact with objects not on screen
remDr$mouseMoveToLocation(webElement = webElem)

webElem$sendKeysToActiveElement(list(key = 'down_arrow', key = 'down_arrow', key = 'enter'))
webElem$sendKeysToActiveElement(list("Hallo World", key = 'enter'))

# -------------------------------------
# Nice to have functions
# -------------------------------------

remDr$maxWindowSize()
remDr$getTitle()
remDr$screenshot(display = TRUE)

b64out<- remDr$screenshot()
writeBin(RCurl::base64Decode(b64out, "raw"), 'screenshot.png')

# Scroll into view
remDr$executeScript("arguments[0].scrollIntoView(true);", args = list(webElem))

# Building a RSelenium pipe function

# RSelenium has 2 types of commands:
#   
# * Those with side-effects (action)
# * Those that returns information we want to push into `rvest`
# 
# For the 1st case, we would want to return the driver object as the state of it has changed

navi <- function(remDr, site = "www.google.com"){
  remDr$navigate(site)
  return(remDr)
}

remDr %>% navi(., "www.google.com")


# -------------------------------------
# Case Study: A Tour of the winelands!
# -------------------------------------

## Extending your wine knowledge

# South Africa is famous for its wines! Lets find out a little bit more about the wine region 
# 
# > * Go to vivino.com
# > * Collect 2 pages worth of information
# > - Name of wine farm, name of wine, star rating, count of ratings


# Display all the wine
library(RSelenium)
remDr <- remoteDriver(remoteServerAddr = "192.168.99.100",
                      port = 4445L, 
                      browser = "chrome")

remDr$open()
remDr$navigate("https://www.vivino.com/")

# This piece isolates the button we need to click on to explore wines
webElem <- remDr$findElement("css", '.explore-widget__main__submit__button')

webElem$highlightElement()
webElem$clickElement()

scrollTo <- function(remDr, webElem){
  remDr$executeScript("arguments[0].scrollIntoView(true);", args = list(webElem))
  webElem$highlightElement()
}
# I use xpath here, just because I want to illustrates the handy function: starts with
# I am trying to isolate where I can fill in the name of the region I am looking to search
webElem <- remDr$findElements("xpath", '//input[starts-with(@class, "filterPills")]')

scrollTo(remDr, webElem[[2]])

webElem[[2]]$clickElement()
webElem[[2]]$sendKeysToActiveElement(list("Australia"))

webElem <- remDr$findElements("css", '.pill__inner--7gfKn')

# How I identify the correct webelem to click on
country_elem <- webElem %>% 
  sapply(., function(x) x$getElementText()) %>% 
  reduce(c) %>% 
  grepl("Australia", .) %>% 
  which

scrollTo(remDr, webElem[[country_elem]])

webElem[[country_elem]]$clickElement()

# Some pages need you to scroll to the bottom in order for more content to load. Vivino is one of them

remDr$executeScript("return window.scrollY", args = list(1))
remDr$executeScript("return document.body.scrollHeight", args = list(1))

remDr$sendKeysToActiveElement(list(key = "end"))
remDr$executeScript("return window.scrollY", args = list(1))

# Now we done with RSelenium, on to rvest!

pg <- remDr$getPageSource() %>% .[[1]] %>% 
  read_html()

collect_info <- function(pg){
  # Get Farm Information
  farm <- pg %>% html_nodes("a.anchor__anchor--3lfA6.vintageTitle__winery--2YoIr") %>% 
    html_text()
  
  # Get Wine Information
  wine <- pg %>% html_nodes("a.anchor__anchor--3lfA6.vintageTitle__wine--U7t9G") %>% 
    html_text()
  
  # Get Rating Information
  rating <- pg %>% html_nodes("span.vivinoRating__rating--4Oti3") %>% 
    html_text() %>% 
    as.numeric
  
  # Get Rating Count Information
  rating_count <- pg %>% html_nodes("span.vivinoRating__ratingCount--NmiVg") %>% 
    html_text() %>% 
    gsub("[^0-9]", "",.) %>% 
    as.numeric
  
  data.frame(farm, wine, rating, rating_count)
}

collect_info(pg)
# ------------------------------#
#  ███████╗███╗   ██╗██████╗    #
#  ██╔════╝████╗  ██║██╔══██╗   #
#  █████╗  ██╔██╗ ██║██║  ██║   #
#  ██╔══╝  ██║╚██╗██║██║  ██║   #
#  ███████╗██║ ╚████║██████╔╝   #
#  ╚══════╝╚═╝  ╚═══╝╚═════╝    #
# ------------------------------#