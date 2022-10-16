plan(multisession)
#future::plan("multicore")

#* @apiTitle Unoficial Twitter API
#* @apiDescription
#* @apiContact list(name = "Youness Bahi", url = "https://github.com/younessbahi/api-googlenews", email = "DAyounessbahi@gmail.com")
#* @apiVersion 1.0


#* @filter cors
cors <-
  function(req, res) {
    res$setHeader("Access-Control-Allow-Origin", "*")
    if (req$REQUEST_METHOD == "OPTIONS") {
      req$setHeader("Access-Control-Allow-Methods", "*")
      req$setHeader("Access-Control-Allow-Headers", req$HTTP_ACCESS_CONTROL_REQUEST_HEADERS)
      req$status <- 200
      return(list())
    } else {
      plumber::forward()
    }
  }


#* @assets ./docs /
list()


#* Get trends
#* @param woeid:str Location ID
#* @get /trend
get_trend <- function(woeid = '1', res, req) {
  if (as.character(woeid) %!in% as.character(loc$woeid)) {
    res$status <- 500
    res$body   <-
      return(
        err_handler(
          status = 1003,
          msg    = glue::glue("Invalid id. Please refer to documentation to get available location ids.")
        )
      )
    res
    
  }
  
  trend_(id = as.character(woeid))
}


#* @get /trend/location/list
get_loc <- function() {
  loc_ <-
    loc %>%
      select(- c(rowID, url)) %>%
      mutate(placeType = unlist(rlist::list.select(placeType, .$name)))
  
  return(
    list(
      locations = loc_
    )
  )
}

#* Get Score
#* @param keyword:str Your target keyword
#* @get /score
get_score <- function(keyword) {
  
  ScoreTbl <- score_(keyword = keyword)
  
  if (is_empty(ScoreTbl$topics)) {
    topicScoreTbl <- list()
  } else {
    topicScoreTbl <- # tidy topic table
      ScoreTbl %>%
        pluck('topics') %>%
        enframe(name = "rowID") %>%
        unnest_wider(value) %>%
        select(- c(tokens, inline))
    
    topicScoreTbl$result_context <- if (is.null(topicScoreTbl$result_context)) '' else  topicScoreTbl$result_context
    
    topicScoreTbl$context.type <-
      if (topicScoreTbl$result_context == '') '' else {
        purrr::map_depth(
          topicScoreTbl$result_context, 1, ~ .$types %>% unlist(use.names = F)
        ) %>% #list to vec
          lapply(., function(e) { if (is_empty(e) | is.null(e)) NA else e }) %>%
          unlist()
      }
    
    topicScoreTbl$context.string <-
      if (topicScoreTbl$result_context == '') '' else {
        purrr::map_depth(
          topicScoreTbl$result_context, 1, ~ .$display_string %>% unlist(use.names = F)
        ) %>% #list to vec
          lapply(., function(e) { if (is_empty(e) | is.null(e)) NA else e }) %>%
          unlist()
      }
    
    topicScoreTbl %<>%
      select(- result_context) %>%
      relocate(rowID, topic, rounded_score, context.type, context.string) %>%
      arrange(desc(rounded_score)) %>%
      mutate(time = Sys.time())
    
  }
  
  
  if (is_empty(ScoreTbl$users)) {
    userScoreTbl <- list()
  } else {
    userScoreTbl <-
      ScoreTbl %>%
        pluck('users') %>%
        enframe(name = "rowID") %>%
        unnest_wider(value)
    
    userScoreTbl$tokens <-
      userScoreTbl %>%
        pluck('tokens') %>%
        enframe(name = "rowID") %>%
        unnest(value) %>%
        mutate(value = unlist(value, use.names = F)) %>%
        group_by(rowID) %>%
        summarise(
          tokens = list(value)
        ) %>%
        pull(tokens)
    
    userScoreTbl$result_context <- if (is.null(userScoreTbl$result_context)) '' else  userScoreTbl$result_context
    
    userScoreTbl$context.type <-
      if (userScoreTbl$result_context == '')  '' else {
        purrr::map_depth(userScoreTbl$result_context, .depth = 1, ~ .$types %>% unlist(use.names = F)) %>% #list to vec
          lapply(., function(e) { if (is_empty(e) | is.null(e)) NA else e }) %>%
          unlist()
      }
    
    userScoreTbl$context.string <-
      if (userScoreTbl$result_context == '') '' else {
        purrr::map_depth(userScoreTbl$result_context, .depth = 1, ~ .$display_string %>% unlist(use.names = F)) %>% #list to vec
          lapply(., function(e) { if (is_empty(e) | is.null(e)) NA else e }) %>%
          unlist()
      }
    
    userScoreTbl %<>%
      select(- c(social_context, result_context, inline)) %>%
      relocate(rowID, screen_name, rounded_score) %>%
      arrange(desc(rounded_score)) %>%
      mutate(time = Sys.time())
    
  }
  
  return(
    list(
      query  = ScoreTbl$query,
      count  = ScoreTbl$num_results,
      topics = topicScoreTbl,
      users  = userScoreTbl
    )
  )
}


#* @get /search
get_search <- function(query = NA, .lat = NA, .long = NA, .radius = NA, .place = NA, .since = NA, .until = NA, .from = NA, .to = NA,
                       .replies = F, .minLikes = NA, .minReplies = NA, .minRetweets = NA, .verified = F, .hasImage = F, .hasVideo = F,
                       .hasMedia = F, .hasLinks = F, .url = NA, .count = '-1', res, req) {
  
  q.clean_ <- search_(query, .lat, .long, .radius, .place, .since, .until, .from, .to, .replies, .minLikes, .minReplies, .minRetweets, .verified,
                      .hasImage, .hasVideo, .hasMedia, .hasLinks, .url)
  
  print(q.clean_) #to remove
  
  if (q.clean_ == "") {
    res$status <- 500
    res$body   <-
      return(
        err_handler(
          status = 1010,
          msg    = glue::glue("Request cannot be blank. You need to provide at least One argument!")
        )
      )
    res
  }
  
  q.parse_ = urltools::url_encode(q.clean_)
  
  source('logic/init.R')
  
  headers = c(
    `authority`                 = 'twitter.com',
    `sec-ch-ua`                 = '";Not A Brand";v="99", "Google Chrome";v="104"',
    `x-twitter-client-language` = 'en',
    `x-csrf-token`              = ct0,
    `sec-ch-ua-mobile`          = '?0',
    `authorization`             = 'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
    `user-agent`                = 'Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1)',
    `x-guest-token`             = gt,
    `x-twitter-active-user`     = 'yes',
    `x-twitter-utcoffset`       = '+0000',
    `sec-ch-ua-platform`        = '"macOS"',
    `accept`                    = '*/*',
    `sec-fetch-site`            = 'same-origin',
    `sec-fetch-mode`            = 'websocket',
    `sec-fetch-dest`            = 'empty',
    `referer`                   = glue::glue('https://twitter.com/search?q={q.parse_}&src=typeahead_click&f=live'),
    `accept-language`           = 'en-US,en;q=0.9'
    #`content-type` = 'application/x-www-form-urlencoded'
  )
  
  params = list(
    `include_profile_interstitial_type`    = '1',
    #`include_blocking` = '1',
    # `include_blocked_by` = '1',
    `include_followed_by`                  = '1',
    #`include_want_retweets` = '1',
    #`include_mute_edge` = '1',
    #`include_can_dm` = '1',
    `include_can_media_tag`                = '1',
    `include_ext_has_nft_avatar`           = '1',
    #`skip_status` = '1',
    #`cards_platform` = 'Web-12',
    #`include_cards` = '1',
    `include_ext_alt_text`                 = 'true',
    `include_quote_count`                  = 'true',
    `include_reply_count`                  = '1',
    `tweet_mode`                           = 'extended',
    `include_ext_collab_control`           = 'true',
    `include_entities`                     = 'true',
    `include_user_entities`                = 'true',
    `include_ext_media_color`              = 'true',
    `include_ext_media_availability`       = 'true',
    `include_ext_sensitive_media_warning`  = 'true',
    `include_ext_trusted_friends_metadata` = 'true',
    `send_error_codes`                     = 'true',
    `simple_quoted_tweet`                  = 'true',
    `q`                                    = q.clean_,
    `tweet_search_mode`                    = 'live',
    #`tweet_count` = '200',
    `count`                                = '60',
    #`max_id` ='100',
    `cursor`                               = '-1',
    `query_source`                         = 'typeahead_click',
    `pc`                                   = '1',
    `spelling_corrections`                 = '1',
    `include_ext_edit_control`             = 'true',
    `ext`                                  = 'mediaStats,highlightedLabel,hasNftAvatar,voiceInfo,enrichments,superFollowMetadata,unmentionInfo,editControl,collab_control,vibe'
  )
  
  count_     = as.numeric(.count)
  pagination = ifelse(.count != '-1', ceiling(count_ / 20), '')

  if (.count != '-1') {
    for (c in seq_along(1:pagination)) {
      i = i + 1
      
      if (i != 1) {
        last.cursor   = cursor
        params$cursor = cursor
        #cat(cursor, fill = T)
      }
      
      res <-
        httr::GET(
          url   = 'https://twitter.com/i/api/2/search/adaptive.json',
          httr::timeout(1800),
          httr::add_headers(.headers = headers),
          query = params,
          set_cookies(cookies = cookies__)
        )
      
      res_ <- content(res)
      
      if (i != 1) {
        
        last   <-
          length(res_$timeline$instructions)
        cursor <-
          res_$
            timeline$
            instructions[[last]]$
            replaceEntry$
            entry$
            content$
            operation$
            cursor$
            value
      } else {
        last   <-
          length(
            res_$
              timeline$
              instructions[[1]]$
              addEntries$
              entries)
        cursor <-
          res_$
            timeline$
            instructions[[1]]$
            addEntries$
            entries[[last]]$
            content$
            operation$
            cursor$
            value
      }
      
      result[[i]] <- append(res_, empty)
      
    }
  } else {
    while (cursor != last.cursor) {
      i = i + 1
      
      if (i != 1) {
        last.cursor   = cursor
        params$cursor = cursor
        #cat(cursor, fill = T)
      }
      
      res <-
        httr::GET(
          url   = 'https://twitter.com/i/api/2/search/adaptive.json',
          httr::add_headers(.headers = headers),
          query = params,
          set_cookies(cookies = cookies__)
        )
      
      res_ <- content(res)
      
      if (i != 1) {
        
        last   <-
          length(res_$timeline$instructions)
        cursor <-
          res_$
            timeline$
            instructions[[last]]$
            replaceEntry$
            entry$
            content$
            operation$
            cursor$
            value
      } else {
        last   <-
          length(
            res_$
              timeline$
              instructions[[1]]$
              addEntries$
              entries)
        cursor <-
          res_$
            timeline$
            instructions[[1]]$
            addEntries$
            entries[[last]]$
            content$
            operation$
            cursor$
            value
      }
      
      result[[i]] <- append(res_, empty)
      
    }
  }
  
  res.data <-
    result %>%
      pluck() %>%
      enframe('rowID') %>%
      unnest_wider(value) %>%
      select(- timeline) %>%
      unnest_wider(globalObjects) %>%
      select(rowID, tweets, users)
  
  rm(result)
  
  if (na.tools::all_na(res.data$tweets)) {
    res$status <- 500
    res$body   <-
      return(
        err_handler(
          status = 1005,
          msg    = glue::glue("No result found for your query. Please try again with new terms")
        )
      )
    res
  }
  
  tidy_ <- function(.x) {
    unlist(.x, recursive = F) %>%
      enframe('rowID') %>%
      unnest_wider(value)
  }
  
  parse_datetime <- function(str_date) {
    as.POSIXct(str_date, format = "%a %b %d %H:%M:%S +0000 %Y", tz = "GMT")
  }
  
  tw.list <-
    tidy_(res.data$tweets) %>%
      mutate(
        at_GMT_time = parse_datetime(created_at) + 3600,
        at_UTC_time = parse_datetime(created_at)
      )
  
  users.list <-
    tidy_(res.data$users) %>%
      mutate(
        created_at = parse_datetime(created_at) + 3600
      )
  rm(res.data)
  print(length(users.list$created_at)) #testing
  
  
  index_rm <- cRm[which(cRm$to_rm %in% names(users.list)),]$to_rm
  users.list %<>% select(- all_of(index_rm))
  
  usr_entity_clean(users = users.list)
  users.list %<>% select(- entities)
  
  tw_entity_clean(tweets = tw.list)
  tw.list %<>%
    select(- c(rowID, created_at, entities, extended_entities, ext, ext_edit_control)) %>%
    arrange(desc(at_GMT_time)) %>%
    relocate(at_GMT_time, at_UTC_time)
  
  if (any(names(tw.list) == 'display_text_range')) {
    tw.list %<>% select(- display_text_range)
  }
  
  
  result_ <-
    list(
      tweets_count       = nrow(tw.list),
      unique_users_count = length(unique(users.list$id_str)),
      tweets             = list(
        items    = tw.list,
        hashtags = hashtags,
        mentions = mentions,
        urls     = tw.urls,
        medias   = tw.media
        #geo = tw.geo
      ),
      users = list(
        items = users.list,
        url   = user.url)
    )
  print(length(result))
  
  if (res$status == 503) {
    res$status == 503
    res$body <- return(result_)
  } else {
    return(result_)
  }
  
}