clean <- function (tweets) {
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
  
  hashtags_ <-
    hashtags %>%
      select(- rowID) %>%
      group_by(id_str) %>%
      summarise(hashtags = list(hashtags))
  
  tweets <- left_join(tweets, hashtags_, by = "id_str")
  
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
  
  #  pluck('urls') %>%
  #  enframe(name = 'id') %>%
  # mutate(rowID = tw.urls$rowID) %>%
  #  unnest_wider(value) %>% View()
  #unnest_wider('...1')
  
  tw.urls$id_str <- pull(tweets[tw.urls$rowID, "id_str"])
  
  tw.urls_ <-
    tw.urls %>%
      select(- c(rowID, url, indices)) %>%
      group_by(id_str) %>%
      summarise(
        expanded_url = list(expanded_url),
        display_url  = list(display_url)
      )
  
  tweets <- left_join(tweets, tw.urls_, by = "id_str")
  
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
  mentions %<>%
    select(- indices)
  
  
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
  
  tw.geo$id_str <- pull(tweets[tw.geo$name, 'id_str']) }