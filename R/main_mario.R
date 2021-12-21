#' Run Mario to create a video
#'
#' @param file An input file, such as a PPTX, Google Slide ID or URL,
#' or a PDF (script needed)
#' @param script A script of the words needed to be said over the slides.
#' @param voice The voice used to synthesize the audio
#' @param target The language code (2-character) to translate to.
#' @param token A Token object for Google Slides for your account.  Usually
#' created from [googledrive::drive_token]
#' @param return_images Should images be base64-encoded if slides are converted
#' to PNG files?
#' @inheritParams mario_voices
#'
#' @return A `response` with the response from the API
#' @export
#'
#' @examples
#' \dontrun{
#' if (mario_have_api_key()) {
#' 
#'   # Google Slide ID
#'   id <- "1Opt6lv7rRi7Kzb9bI0u3SWX1pSz1k7botaphTuFYgNs"
#'   
#'   # Use Mario
#'   res <- mario(id)
#'   
#'   # Check URL 
#'   httr::stop_for_status(res)
#'   
#'   if (requireNamespace("ariExtra", quietly = TRUE)) {
#'   
#'     # Using PDF
#'     pdf_file <- system.file("extdata", "example.pdf", package = "ariExtra")
#'     script <- tempfile(fileext = ".txt")
#'     paragraphs <- c("hey", "ho")
#'     writeLines(paragraphs, script)
#'
#'     # Trying with script or paragraphs
#'     res <- mario(pdf_file, script, return_images = TRUE)
#'     httr::stop_for_status(res)
#'     out <- mario_content(res)
#'     res <- mario(pdf_file, paragraphs)
#'     httr::stop_for_status(res)
#'
#'
#'     # Using PPTX
#'     file <- system.file("extdata", "example.pptx", package = "ariExtra")
#'     res <- mario(file)
#'     # Set of PNGs
#'     file <- system.file("extdata", c("example_1.png", "example_2.png"),
#'       package = "ariExtra"
#'     )
#'
#'     res <- mario(file, script)
#'     httr::stop_for_status(res)
#'     res <- mario(file, paragraphs)
#'     httr::stop_for_status(res)
#'
#'     id <- paste0(
#'       "https://docs.google.com/presentation/d/",
#'       "1Tg-GTGnUPduOtZKYuMoelqUNZnUp3vvg_7TtpUPL7e8",
#'       "/edit#slide=id.g154aa4fae2_0_58"
#'     )
#'     
#'     id <- ariExtra::get_slide_id(id)
#'     words <- strsplit(
#'       c(
#'         "hey what do you think of this thing? ",
#'         "I don't know what to type here."
#'       ),
#'       split = " "
#'     )
#'     script <- tempfile(fileext = ".txt")
#'     script <- writeLines(
#'       rep(unlist(words),
#'         length.out = 41
#'       ),
#'       con = script
#'     )
#'
#'     if (requireNamespace("googledrive", quietly = TRUE)) {
#'       token <- googledrive::drive_token()
#'       out <- mario(
#'         file = id,
#'         script = script,
#'         token = token,
#'         target = "es"
#'       )
#'     }
#'   }
#' }
#' }
mario <- function(file,
                  output_file = NULL,
                  script = NULL,
                  api_url = mario_api_url(),
                  api_key = Sys.getenv("CONNECT_API_KEY"),
                  voice = NULL,
                  service = NULL,
                  target = NULL,
                  token = NULL,
                  return_images = FALSE,
                  ...) {
  auth_hdr <- mario_auth(api_key)

  # Set up file input
  if (all(file.exists(file))) {
    
    zipfile <- tempfile(fileext = ".zip")
    utils::zip(zipfile, files = file)
    file <- zipfile
    
    body <- list(
      file = httr::upload_file(file)
    )
  } else {
    # If given a google slide id, store it
    body <- list(
      file = file
    )
  }

  # If script is given, read it
  if (is.character(script) && !file.exists(script)) {
    message("writing out script to a file")
    paragraphs <- script
    script <- tempfile(fileext = ".txt")
    writeLines(paragraphs, script)
  }
  if (!is.null(script) && file.exists(script)) {
    script <- httr::upload_file(script)
  }

  body$script <- script
  body$service <- service
  body$voice <- voice
  body$return_images <- return_images
  
  if (!is.null(target) && is.null(token)) {
    stop("If target specified, token needs to be set")
  }
  
  body$target <- target
  
  if (!is.null(token)) {
    if (inherits(token, "Token")) {
      tokenfile <- tempfile(fileext = ".rds")
      saveRDS(token, file = tokenfile)
      token <- tokenfile
    }
    stopifnot(file.exists(token))
    token <- httr::upload_file(token)
  }
  
  body$token <- token

  # Send the request to the API 
  response <- httr::POST(
    url = paste0(api_url, "/to_ari"),
    body = body,
    auth_hdr, ...
  )
  # Write to a video!
  mario_write_video(response, 
                    output_file = output_file)
}


#' @rdname mario
#' @export
mario_translate <- function(file,
                            api_url = mario_api_url(),
                            api_key = Sys.getenv("CONNECT_API_KEY"),
                            target = NULL,
                            token = NULL,
                            ...) {
  auth_hdr <- mario_auth(api_key)

  if (all(file.exists(file))) {
    zipfile <- tempfile(fileext = ".zip")
    utils::zip(zipfile, files = file)
    file <- zipfile
    body <- list(
      file = httr::upload_file(file)
    )
  } else {
    # google slide ids
    body <- list(
      file = file
    )
  }


  if (!is.null(target) && is.null(token)) {
    stop("If target specified, token needs to be set")
  }
  body$target <- target
  if (!is.null(token)) {
    if (inherits(token, "Token")) {
      tokenfile <- tempfile(fileext = ".rds")
      saveRDS(token, file = tokenfile)
      token <- tokenfile
    }
    stopifnot(file.exists(token))
    token <- httr::upload_file(token)
  }
  body$token <- token

  response <- httr::POST(
    url = paste0(api_url, "/translate_slide"),
    body = body,
    auth_hdr, ...
  )
  response
}
