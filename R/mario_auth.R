#' Authorization Header for mario
#'
#' @param api_key API key for RStudio Cnnect
#'
#' @return A `header` output
#' @export
#'
#' @examples
#' out <- mario_auth()
#' if (mario_have_api_key()) {
#'   mario_api_key()
#' }
mario_auth <- function(api_key = Sys.getenv("CONNECT_API_KEY")) {
  auth_hdr <- NULL
  if (nzchar(api_key) && !is.null(api_key)) {
    auth_hdr <- httr::add_headers(
      Authorization = paste0("Key ", api_key)
    )
  }
  
  if (!mario_have_api_key()) {
    warning("No API Key found")
  }
  auth_hdr
}

#' @rdname mario_auth
#' @export
mario_api_url <- function() {
  "https://rsconnect.biostat.jhsph.edu/mario"
}

#' @rdname mario_auth
#' @export
mario_api_key <- function(api_key = Sys.getenv("CONNECT_API_KEY")) {
  stopifnot(!is.null(api_key))
  stopifnot(!api_key %in% "")
  return(api_key)
}

#' @rdname mario_auth
#' @export
mario_have_api_key <- function(api_key = Sys.getenv("CONNECT_API_KEY")) {
  api_key <- try(mario_api_key(api_key = api_key), silent = TRUE)
  if (inherits(api_key, "try-error")) {
    return(FALSE)
  }
  return(!is.null(api_key) && !api_key %in% "")
}
