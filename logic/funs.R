usr_entity_clean <- function (users) {
  
  entities_usr <-
    users %>%
      pluck('entities') %>%
      enframe() %>%
      unnest_wider(value)
  
  user.url_ <-
    entities_usr %>%
      select(name, url) %>%
      rename(rowID = name)
  
  user.url <-
    user.url_ %>%
      pluck('url') %>%
      enframe('rowID')
  
  user.url$value <- lapply(user.url$value, function(e) { if (is_empty(e)) NA else e })
  user.url %<>%
    unnest(value) %>%
    pluck('value') %>%
    enframe('rowID')
  
  user.url$value <- lapply(user.url$value, function(e) { if (is_empty(e)) NA else e })
  user.url %<>%
    unnest(value) %>%
    unnest_wider(value) %>%
    mutate(
      rowID = user.url_$rowID,
      usr_id_str = pull(users[rowID, "id_str"])
    ) %>%
    select(- c(indices, rowID))
  
  user.url <<- user.url
}

tw_entity_clean <- function (tweets) {
  entities <-
    tweets %>%
      pluck('entities') %>%
      enframe() %>%
      unnest_wider(value)
  
  ## Hashtags ####
  #/ linkage with tweets rowID /
  hashtags <-
    entities %>%
      select(name, hashtags,) %>%
      rename(rowID = name)
  
  hashtags$hashtags <- map_depth(hashtags$hashtags, 2, ~ .$text)
  
  hashtags$hashtags <-
    lapply(
      hashtags$hashtags,
      function(e) { if (is_empty(e)) NA else e }
    )
  
  hashtags %<>%
    unnest(cols = hashtags) %>%
    unnest(cols = hashtags)
  
  hashtags$id_str <- pull(tweets[hashtags$rowID, "id_str"])
  
  hashtags <<- hashtags
  # hashtags_ <-
  #   hashtags %>%
  #     select(- rowID) %>%
  #     group_by(id_str) %>%
  #     summarise(hashtags = list(hashtags))
  
  #tw.list <- left_join(tweets, hashtags_, by = "id_str")
  
  ## URLS ####
  tw.urls <-
    entities %>%
      select(name, urls) %>%
      rename(rowID = name)
  
  tw.urls$urls <- lapply(tw.urls$urls, function(e) { if (is_empty(e)) NA else e })
  
  tw.urls <-
    tw.urls %>%
      unnest(cols = 'urls') %>%
      unnest_wider('urls')
  
  tw.urls$id_str <- pull(tweets[tw.urls$rowID, "id_str"])
  
  # tw.urls_ <-
  #   tw.urls %>%
  #     select(- c(rowID, url, indices)) %>%
  #     group_by(id_str) %>%
  #     summarise(
  #       expanded_url = list(expanded_url),
  #       display_url  = list(display_url)
  #     )
  
  #tw.list <<- left_join(tw.list, tw.urls_, by = "id_str")
  
  if (any(names(tw.urls) == 'indices')) {
    tw.urls %<>% select(- indices)
  }
  tw.urls <<- tw.urls# %>% select(- indices)
  
  ## Mentions ####
  #/ linkage with tweets rowID /
  mentions <-
    entities %>%
      select(name, user_mentions)
  
  mentions$user_mentions <-
    lapply(
      mentions$user_mentions,
      function(e) { if (is_empty(e)) NA else e }
    )
  
  mentions %<>%
    unnest(user_mentions)
  
  mentions %<>% pluck('user_mentions') %>%
    enframe(name = 'rowID') %>%
    mutate(rowID = mentions$name) %>%
    unnest_wider(value)
  
  mentions$id_str <- pull(tweets[mentions$rowID, "id_str"])
  mentions$id     <- as.character(mentions$id)
  
  if (any(names(mentions) == 'indices')) {
    mentions %<>% select(- indices)
  }
  
  mentions <<- mentions
  
  ## MEDIAS ####
  tw.media <-
    entities %>%
      select(name, media) %>%
      rename(rowID = name)
  
  tw.media$media <- lapply(tw.media$media, function(e) { if (is_empty(e)) NA else e })
  
  tw.media <-
    unnest(tw.media, cols = 'media')
  
  tw.media_ <-
    tw.media %>%
      pluck('media') %>%
      enframe('rowID') %>%
      mutate(rowID = tw.media$rowID) %>%
      unnest_wider(value)
  
  tw.media_$id_tweet <- pull(tweets[tw.media_$rowID, 'id_str'])
  tw.media <<- tw.media_ %>% select(- c(indices, original_info, sizes))
  
  ## GEO ####
  tw.geo <-
    tweets %>%
      select(id_str, user_id_str, geo) %>%
      pluck('geo') %>%
      enframe() %>%
      filter(! is.na(value)) %>%
      unnest_wider(value) %>%
      pluck('coordinates') %>%
      enframe() %>%
      unnest_wider(value) %>%
      set_colnames(c('name', 'lat', 'long')) %>%
      na.omit()
  try(print(tw.geo), silent = T)
  tw.geo$id_str <- pull(tweets[tw.geo$name, 'id_str'])
  tw.geo <<- tw.geo
}


trend_ <- function(id = '1') {
  
  source('logic/init.R')
  
  headers = c(
    `authority`                 = 'twitter.com',
    `accept`                    = '*/*',
    `accept-language`           = 'en-US,en;q=0.9,fr;q=0.8',
    `authorization`             = 'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
    `referer`                   = glue::glue('https://twitter.com/search?q={q.parse_}&src=typed_query&f=live'),
    `sec-ch-ua`                 = '"Chromium";v="104", " Not A;Brand";v="99", "Google Chrome";v="104"',
    `sec-ch-ua-mobile`          = '?0',
    `sec-ch-ua-platform`        = '"macOS"',
    `sec-fetch-dest`            = 'empty',
    `sec-fetch-mode`            = 'cors',
    `sec-fetch-site`            = 'same-origin',
    `user-agent`                = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36',
    `x-csrf-token`              = ct0,
    `x-guest-token`             = gt,
    `x-twitter-active-user`     = 'yes',
    `x-twitter-client-language` = 'en'
  )
  
  params = list(
    `id` = id #get place id from locID.rds
  )
  
  req.trends <-
    httr::GET(
      url   = 'https://api.twitter.com/1.1/trends/place.json',
      httr::add_headers(.headers = headers),
      query = params,
      httr::set_cookies(.cookies = cookies__)
    )
  
  trends <- content(req.trends)
  
  trend.df <-
    trends[[1]] %>%
      pluck('trends') %>%
      enframe(name = "rowID") %>%
      unnest_wider(value) %>%
      arrange(desc(tweet_volume)) %>%
      mutate(time = Sys.time()) # track ranking overtime
  
  return(trend.df)
}


score_ <- function(keyword) {
  
  source('logic/init.R')
  
  headers =  c(
    `authority`                 = 'twitter.com',
    `accept`                    = '*/*',
    `accept-language`           = 'en-US,en;q=0.9,fr;q=0.8',
    `authorization`             = 'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
    `referer`                   = glue::glue('https://twitter.com/search?q={keyword}&src=typed_query&f=live'),
    `sec-ch-ua`                 = '"Chromium";v="104", " Not A;Brand";v="99", "Google Chrome";v="104"',
    `sec-ch-ua-mobile`          = '?0',
    `sec-ch-ua-platform`        = '"macOS"',
    `sec-fetch-dest`            = 'empty',
    `sec-fetch-mode`            = 'cors',
    `sec-fetch-site`            = 'same-origin',
    `user-agent`                = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36',
    `x-csrf-token`              = ct0,
    `x-guest-token`             = gt,
    `x-twitter-active-user`     = 'yes',
    `x-twitter-client-language` = 'en'
  )
  
  params = list(
    `q`           = keyword,
    `src`         = 'search_box',
    `result_type` = 'users,topics,tweets'
  )
  
  res <- httr::GET(url = 'https://twitter.com/i/api/1.1/search/typeahead.json', httr::add_headers(.headers = headers), query = params, httr::set_cookies(.cookies = cookies__))
  return(
    content(res)
  )
  
}


search_ <- function (query, .lat, .long, .radius, .place, .since, .until, .from, .to, .replies, .minLikes,
                     .minReplies, .minRetweets, .verified, .hasImage, .hasVideo, .hasMedia, .hasLinks, .url) {
  
  config <- list()
  
  #### Any
  .sTerm = as.character(query)  #default to NULL
  sTerm  = if (is.na(.sTerm)) '' else .sTerm
  
  
  #### Location
  ## Geocode ----
  #default to NA
  lat    <- as.character(.lat) #"33.575692"
  long   <- as.character(.long) #"-7.625285"
  radius <- as.character(.radius) #"100km"
  
  geo <- c()
  
  config$geo$lat    <- lat
  config$geo$long   <- long
  config$geo$radius <- radius
  index             <- which(is.na(config$geo))
  
  if (na.tools::all_na(config$geo)) {
    geo <- ''
  } else if (length(index) != 0) {
    msg <- if (length(index) > 1) 'are' else 'is'
    cat(paste(shQuote(names(config$geo[index])), collapse = " and "), msg, 'missing', fill = T)
    geo <- ''
  } else {
    geo <- glue::glue("geocode:{config$geo$lat},{config$geo$long},{config$geo$radius}")
    
  }
  
  ## Place ----
  place_ = as.character(.place) #default to NA
  place  = if (is.na(place_)) '' else { paste0("near:", place_) }
  
  #### Dates
  #/ format: 2022-09-05T00:00:00.0000Z /
  ## Filter:until ----
  until.date <- as.character(.until) #default to NA {YYY/MM/DD}
  if (! is.na(until.date)) {
    until.datetime <- paste0(as.Date(until.date) + 1, 'T00:00:01')
    until          <- glue::glue("until:{until.datetime}")
  } else {
    until <- ''
  }
  
  ## Filter:Since ----
  since.date <- as.character(.since) #'2022-9-1'
  if (! is.na(since.date)) {
    since.datetime <- paste0(as.Date(since.date), 'T00:00:01')
    since          <- glue::glue("since:{since.datetime}")
  } else {
    since <- ''
  }
  ## From ----
  from_ = as.character(.from) # '@CBCNews' #default NULL
  from  = if (is.na(from_)) '' else paste0('from:', from_)
  
  ## To ----
  to_ = as.character(.to) # default NULL
  to  = if (is.na(to_)) '' else paste0('to:', to_)
  
  #### Filters
  ## Filter:replies ----
  replies_ = as.logical(toupper(.replies)) #logical
  replies  = if (replies_ == FALSE) '' else { "filter:replies" }
  
  ## Filter:minLikes ----
  minLikes_ = as.character(.minLikes) #default NULL
  minLikes  = if (is.na(minLikes_)) '' else paste0('min_faves:', minLikes_)
  
  ## Filter:minReplies ----
  minReplies_ = as.character(.minReplies) #default NULL
  minReplies  = if (is.na(minReplies_)) '' else paste0('min_replies:', minReplies_)
  
  ## Filter:minRetweets ----
  minRetweets_ = as.character(.minRetweets) #default NULL
  minRetweets  = if (is.na(minRetweets_)) '' else paste0('min_retweets:', minRetweets_)
  
  ## Filter:verified ----
  verified_ = as.logical(toupper(.verified)) #logical
  verified  = if (verified_ == FALSE) '' else { "filter:verified" }
  
  ## Filter:images ----
  hasImage_ <- as.logical(toupper(.hasImage))  #logical
  hasImage  <- if (hasImage_ == FALSE) '' else { "filter:images" }
  
  ## Filter:videos ----
  hasVideo_ <- as.logical(toupper(.hasVideo))  #logical
  hasVideo  <- if (hasVideo_ == FALSE) '' else { "filter:videos" }
  
  ## Filter:media ----
  hasMedia_ <- as.logical(toupper(.hasMedia))  #logical
  hasMedia  <- if (hasMedia_ == FALSE) '' else { "filter:media" }
  
  ## Filter:links ----
  hasLinks_ <- as.logical(toupper(.hasLinks))  #logical
  hasLinks  <- if (hasLinks_ == FALSE) '' else { "filter:links" }
  
  ## Filter:domain ----
  #When a domain name is specified, such as oscars.org, the tweets containing domain and subdomain links are returned. If only one term is entered (ex:oscars), links from all websites that belong to that term will be returned.
  url_ = as.character(.url) #default NULL
  url  = if (is.na(url_)) '' else paste0('url:', url_)
  
  q        = paste(sTerm, from, to, until, since, place, geo, minLikes, minReplies, minRetweets, verified, hasImage, hasVideo, hasMedia, hasLinks, url)
  q.clean  = stringr::str_replace_all(q, "\\s{2,}", " ") %>% stringr::str_trim("both")
  
  return(q.clean)
  
}