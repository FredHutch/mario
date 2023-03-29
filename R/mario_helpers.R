#' List Voices available
#'
#' @param service Service to use or list voices
#' @param api_url URL for the Plumber API
#' @inheritParams mario_auth
#' @param ... additional options to send to \code{\link{GET}}
#'
#' @return A `data.frame` of voices
#' @export
#'
#' @examples
#' if (mario_have_api_key()) {
#'   result <- mario_voices()
#'   utils::head(result)
#' }
mario_voices <- function(service = NULL,
                         api_url = mario_api_url(),
                         api_key = Sys.getenv("CONNECT_API_KEY"),
                         ...) {
  
  auth_hdr <- mario_auth(api_key)
  query <- list()
  query$service <- service
  response <- httr::GET(
    url = paste0(api_url, "/list_voices"),
    query = query,
    auth_hdr, ...
  )
  httr::stop_for_status(response)
  out <- jsonlite::fromJSON(
    httr::content(response, as = "text"),
    flatten = TRUE
  )
  out
  # response
}