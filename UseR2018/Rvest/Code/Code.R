##########################################################
#
#     HANJO ODENDAAL 
#     hanjo.oden@gmail.com
#     www.daeconomist.com
#     @UbuntR314
#     https://github.com/HanjoStudy
#     
#
#      ██████╗ ██╗   ██╗███████╗███████╗████████╗
#      ██╔══██╗██║   ██║██╔════╝██╔════╝╚══██╔══╝
#      ██████╔╝██║   ██║█████╗  ███████╗   ██║   
#      ██╔══██╗╚██╗ ██╔╝██╔══╝  ╚════██║   ██║   
#      ██║  ██║ ╚████╔╝ ███████╗███████║   ██║   
#      ╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝   ╚═╝   
#     
#      Last update: July 2018
#     
##########################################################



# -------------------------------------
# Crawl-delay 
# -------------------------------------
# Remember as part of the commandments we must ensure our scraper behaves well and not try an access all files all at once. How do we ensure our scrapers behave well? The `crawl_delay` feature comes into play here:

rtxt <- robotstxt(domain = "www.fbi.gov")
rtxt$comments %>% tbl_df  
rtxt$crawl_delay

# But what if the `robottxt` file we downloaded did not contain any information?
# Then sleep for around 5 - 10 seconds between calls

browseURL("https://i1.wp.com/rud.is/b/wp-content/uploads/2017/07/Cursor_and_RStudio.png?ssl=1")

# What do I mean by sleeping between calls?
# We need to tell `R` to not go absolutely beserek and try and get all the pages we want to investigate at once, we do this using the `Sys.sleep` command. I am going to build a nice function which can take of this for us

nytnyt <- function (periods = c(1,1.5)){
  # draw from a uniform distribution a single number between params
  tictoc <- runif(1, periods[1], periods[2])
  
  # Use a nice verbose output to communicate your intent
  cat(paste0(Sys.time()), "- Sleeping for ", round(tictoc, 2), "seconds\n")
  
  # Implement the sleeper
  Sys.sleep(tictoc)
}

# Always rememebr to test!
nytnyt()

# -------------------------------------
# Rvest
# -------------------------------------

# Installing rvest
# Easy har-*vest*-ing of static websites. Welcome to rvest

if(!require(rvest)) install.packages("rvest")
library(rvest)

# If you have used `XML` before, `rvest` is a dish of the same flavour
# Here I read in the result from the website ipify.org
read_html("https://api.ipify.org?format=json")

# Our first rvest function
# Running this command line for gives us an idea of some of the basic functions of `rvest`. We might always want to get an idea of our ip before we start scraping

get_ip <- function(){
  # read in from website
  read_html("https://api.ipify.org?format=json") %>% 
    # convert to text
    html_text() %>% 
    # convert from json
    jsonlite::fromJSON()
}

# Well done, you hacker you!

# -------------------------------------
# Rvest functions: html_table()
# -------------------------------------

getAnywhere("html_table")
methods("html_table")
rvest:::html_table.xml_document
#rvest:::html_table.xml_node

# Lucky for us, we don't need to know what is happening in the background! I am going to explore the rugby world Cup information from wikipedia

rugby <- read_html("https://en.wikipedia.org/wiki/Rugby_World_Cup")

# Use html_table to read in the information from the wikipedia site and be sure to fill ;-)
rugby_tables <- rugby %>% html_table(., fill = T)

# html_table will always return a list object - thus, use view to have a quick check which list you need
# In this case I need table 3, I also convert the names to lower case and replace all spaces with '_'

correct_names <- function(df){
  df %>% purrr::set_names(., gsub(" ", "_", tolower(names(.))))
}

library(scales)
rugby_tables %>%
  .[[3]] %>%
  correct_names() %>% 
  mutate(total_attendance = as.numeric(gsub("[^0-9.-]+", "", total_attendance))) %>%
  ggplot(., aes(year, total_attendance, fill = total_attendance)) +
  geom_bar(stat = "Identity") +
  labs(title = "World Cup Rugby Attendance",
       subtitle = "1987 - 2015") +
  scale_y_continuous(label = comma) +
  theme_light()

# -------------------------------------
# Rvest functions: html_nodes()
# -------------------------------------

# Understanding the structure of the DOM and its tree like structure
browseURL("https://bit.ly/2JJcTdv")

# Ok, lets see how we can use the nodes to extract data
# Using the selector gadget, we can identify nodes within the DOM, that we would like to focus on

# using xpath
rugby %>%
  html_nodes(., xpath = '//*[(@id = "toc")]') %>%
  html_text %>%
  cat

# using css
rugby %>%
  html_nodes(., css = 'div#toc.toc') %>%
  html_text %>%
  cat

# more on xpath:
browseURL("https://bit.ly/2ycoNvd")
browseURL("https://bit.ly/2JBQz9Q")


# -------------------------------------
# Rvest functions: html_session()
# -------------------------------------

# Once you have basic static website scraping down, you need to start learning about sessions. What does this mean?
# cookies
# header requests
# status codes

# In essence you will be simulating browser activity. Do note, its different from a browser in that it cannot render javascript, but it can simulate moving through static webpages 
# So what does a session object contain?

(rugby <- read_html("https://en.wikipedia.org/wiki/Rugby_World_Cup"))

(rugby <- html_session("https://en.wikipedia.org/wiki/Rugby_World_Cup"))

# There are also some useful linking functions if you know the matching character text
rugby <- rugby %>% 
  follow_link("Australia")

# There are also some useful linking functions if you know the matching character text
rugby %>% 
  back() %>% 
  jump_to("https://en.wikipedia.org/wiki/South_Africa_national_rugby_union_team")

# This becomes useful when you are interacting with websites; lets take a look at forms

# -------------------------------------
# Rvest functions: html_from()
# -------------------------------------

# So to interact with forms, we are going to use `html_session` and `html_form`
rugby <- html_session("https://en.wikipedia.org/wiki/Rugby_World_Cup")

(rugby_form <- rugby %>% html_form())

# You can see that the form is in a list object, so remember to extract the from object from the list
(rugby_form <- rugby %>% html_form() %>% .[[1]])

# Next, we can actually fill in the form using `set_values`

# This can either be done through a very manual process
(rugby_form$fields$search$value <- "cricket")

# Or by using the set_values function
(rugby_form <- set_values(rugby_form, search = "cricket"))

# lastly remember to submit the form!
cricket <- submit_form(rugby, rugby_form)

# -------------------------------------
# Concluding Rvest
# -------------------------------------
# Rvest is an amazing package for static website scraping and session control. For 90% of the websites out their, rvest will enable you to collect information in a well organised manner. For the other 10% you will need Selenium. Tomorrow we will see how to combine these 2 forces in the next sessions


# -------------------------------------
# Case Study
# -------------------------------------
# Putting it all into practice

# So go onto imdb and find your favourite film
# Collect all of 'People who liked this also liked...' movie links
# Collect and plot the gross USA amount of each of the movies using GGplot

# My favourite movie is Amelie
movies <- read_html("https://www.imdb.com/title/tt0211915/?ref_=fn_al_tt_1")

# My plan of action is to build 2 functions achieve the right results:

# get_recom: Should retrieve the links to all the related movies
# movie_gross: Get the gross income per recommended movie
# Plot using ggplot

get_recom <- function(movies) {
  
  # First the names of the related movies
  names <- movies %>%
    html_nodes("div.rec_view") %>%
    html_nodes("img") %>%
    html_attr("title")
  
  # Next the links to the movies
  links <- movies %>%
    html_nodes("div.rec_view") %>%
    html_nodes("a") %>%
    html_attr("href") %>%
    .[!is.na(.)] %>%
    paste0("https://www.imdb.com", .) # Don't forget to add the root url
  
  # lastly combine in a neat df
  data.frame(names, links)
}

movie_gross <- function(movies) {
  movies %>%
    # I have to use the big txt-block as the text is in the div, not the h4 block
    html_nodes("div.txt-block") %>%
    html_text() %>%
    # I look for the single node that contained to Gross using grepl
    .[grepl("Gross USA", .)] %>%
    # Now the regex starts, i isolate the numbers that come after the dollar
    gsub(".* \\$(.*), .*", "\\1", .) %>%
    # Then I use regex to get the numbers
    gsub("[^0-9]", "", .) %>%
    as.numeric
}


movies <-
  read_html("https://www.imdb.com/title/tt0211915/?ref_=fn_al_tt_1")

# Test my functions
recommendations <- get_recom(movies)
gross <- movie_gross(movies)

# I prefer using lists to store objects, expecially because you dont always know what is coming back
# Always run the loop through with i = 1
# You dont wanna find out you forgot to dynamically assign the index (ex recommendations[1, 'names']) and find the same result

all_movies <- list()
for (i in 1:nrow(recommendations)) {
  cat("Now collecting gross income for:", recommendations[i, 'names'], "\n")
  all_movies[[i]] <- read_html(recommendations[i, 'links']) %>%
    movie_gross()
  
  # Remember to be nice and sleep
  nytnyt(c(1, 2))
}

# I will now bind the list using rbind

all_movies %>%
  do.call(rbind, .) %>%
  cbind(recommendations, gross = . / 1e6) %>%
  ggplot(., aes(reorder(names, gross), gross, fill = gross)) +
  geom_bar(stat = "Identity") +
  coord_flip() +
  theme_minimal()

# ------------------------------#
#  ███████╗███╗   ██╗██████╗    #
#  ██╔════╝████╗  ██║██╔══██╗   #
#  █████╗  ██╔██╗ ██║██║  ██║   #
#  ██╔══╝  ██║╚██╗██║██║  ██║   #
#  ███████╗██║ ╚████║██████╔╝   #
#  ╚══════╝╚═╝  ╚═══╝╚═════╝    #
# ------------------------------#
