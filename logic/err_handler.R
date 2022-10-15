
err_handler <-
  function(status, helper = NULL, msg, res, req) {
    if (! is.null(helper)) {
      return(
        list(
          error   = status,
          message = msg,
          guide   = helper
        )
      )
    } else {
      return(
        list(
          error   = status,
          message = msg
        )
      )
    }
  }