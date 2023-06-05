#' Authorization Header for mario
#'
#' @param api_key API key for RStudio Connect
#'
#' @return A `header` output
#' @export
#'
#' @examples
#' out = mario_auth()
#' if (mario_have_api_key()) {
#' mario_api_key()
#' }
mario_auth = function(api_key = Sys.getenv("CONNECT_API_KEY")) {
  auth_hdr = NULL
  if (nzchar(api_key) && !is.null(api_key)) {
    auth_hdr = httr::add_headers(
      Authorization = paste0("Key ", api_key))
  }
  auth_hdr
}

# URL to RSConnect that contains mario API
#' @rdname mario_auth
#' @export
mario_api_url = function() {
  "https://rsconnect.biostat.jhsph.edu/mario"
}

# Return API Key
#' @rdname mario_auth
#' @export
mario_api_key = function(api_key = Sys.getenv("CONNECT_API_KEY")) {
  stopifnot(!is.null(api_key))
  stopifnot(!api_key %in% "")
  return(api_key)
}

# Check if user has API key
#' @rdname mario_auth
#' @export
mario_have_api_key = function(api_key = Sys.getenv("CONNECT_API_KEY")) {
  api_key = try(mario_api_key(api_key = api_key), silent = TRUE)
  if (inherits(api_key, "try-error")) return(FALSE)
  return(!is.null(api_key) && !api_key %in% "")
}



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
#'     result = mario_voices()
#'     utils::head(result)
#' }
mario_voices = function(
  service = NULL,
  api_url = "https://rsconnect.biostat.jhsph.edu/mario",
  api_key = Sys.getenv("CONNECT_API_KEY"),
  ...
) {

  auth_hdr = mario_auth(api_key)
  query = list()
  query$service = service
  response = httr::GET(
    url = paste0(api_url, "/list_voices"),
    query = query,
    auth_hdr, ...)
  httr::stop_for_status(response)
  out = jsonlite::fromJSON(
    httr::content(response, as = "text"),
    flatten = TRUE)
  out
  # response
}

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
#'   # Google Slide ID
#'   id = "1Opt6lv7rRi7Kzb9bI0u3SWX1pSz1k7botaphTuFYgNs"
#'   res = mario(id)
#'   httr::stop_for_status(res)
#'   if (requireNamespace("ariExtra", quietly = TRUE)) {
#'     # Using PDF
#'     pdf_file = system.file("extdata", "example.pdf", package = "ariExtra")
#'     script = tempfile(fileext = ".txt")
#'     paragraphs = c("hey", "ho")
#'     writeLines(paragraphs, script)
#'
#'     # Trying with script or paragraphs
#'     res = mario(pdf_file, script, return_images = TRUE)
#'     httr::stop_for_status(res)
#'     out = mario_content(res)
#'     res = mario(pdf_file, paragraphs)
#'     httr::stop_for_status(res)
#'
#'
#'     # Using PPTX
#'     file = system.file("extdata", "example.pptx", package = "ariExtra")
#'     res = mario(file)
#'     # Set of PNGs
#'     file = system.file("extdata", c("example_1.png", "example_2.png"),
#'                        package = "ariExtra")
#'
#'     res = mario(file, script)
#'     httr::stop_for_status(res)
#'     res = mario(file, paragraphs)
#'     httr::stop_for_status(res)
#'
#'
#'
#'
#'     id = paste0("https://docs.google.com/presentation/d/",
#'                 "1Tg-GTGnUPduOtZKYuMoelqUNZnUp3vvg_7TtpUPL7e8",
#'                 "/edit#slide=id.g154aa4fae2_0_58")
#'     id = ariExtra::get_slide_id(id)
#'     words = strsplit(
#'       c("hey what do you think of this thing? ",
#'         "I don't know what to type here."), split = " ")
#'     script = tempfile(fileext = ".txt")
#'     script = writeLines(
#'       rep(unlist(words),
#'           length.out = 41), con = script)
#'
#'     if (requireNamespace("googledrive", quietly = TRUE)) {
#'       token = googledrive::drive_token()
#'       out = mario(file = id,
#'                   script = script,
#'                   token = token,
#'                   target = "es")
#'     }
#'   }
#' }
#' }
mario = function(
  file,
  script = NULL,
  api_url = mario_api_url(),
  api_key = Sys.getenv("CONNECT_API_KEY"),
  voice = NULL,
  service = NULL,
  target = NULL,
  token = NULL,
  return_images = FALSE,
  ...
) {
  auth_hdr = mario_auth(api_key)

  if (all(file.exists(file))) {
    zipfile = tempfile(fileext = ".zip")
    utils::zip(zipfile, files = file)
    file = zipfile
    body = list(
      file = httr::upload_file(file)
    )
  } else {
    # google slide ids
    body = list(
      file = file
    )
  }


  if (is.character(script) &&
      !file.exists(script)) {
    message("writing out script to a file")
    paragraphs = script
    script = tempfile(fileext = ".txt")
    writeLines(paragraphs, script)
  }
  if (!is.null(script) && file.exists(script)) {
    script = httr::upload_file(script)
  }

  body$script = script
  body$service = service
  body$voice = voice
  body$return_images = return_images
  if (!is.null(target) && is.null(token)) {
    stop("If target specified, token needs to be set")
  }
  body$target = target
  if (!is.null(token)) {
    if (inherits(token, "Token")) {
      tokenfile = tempfile(fileext = ".rds")
      saveRDS(token, file = tokenfile)
      token = tokenfile
    }
    stopifnot(file.exists(token))
    token = httr::upload_file(token)
  }
  body$token = token

  response = httr::POST(
    url = paste0(api_url, "/to_ari"),
    body = body,
    auth_hdr, ...)
  response
}


#' @rdname mario
#' @export
mario_translate = function(
  file,
  api_url = mario_api_url(),
  api_key = Sys.getenv("CONNECT_API_KEY"),
  target = NULL,
  token = NULL,
  ...
) {
  auth_hdr = mario_auth(api_key)

  if (all(file.exists(file))) {
    zipfile = tempfile(fileext = ".zip")
    utils::zip(zipfile, files = file)
    file = zipfile
    body = list(
      file = httr::upload_file(file)
    )
  } else {
    # google slide ids
    body = list(
      file = file
    )
  }


  if (!is.null(target) && is.null(token)) {
    stop("If target specified, token needs to be set")
  }
  body$target = target
  if (!is.null(token)) {
    if (inherits(token, "Token")) {
      tokenfile = tempfile(fileext = ".rds")
      saveRDS(token, file = tokenfile)
      token = tokenfile
    }
    stopifnot(file.exists(token))
    token = httr::upload_file(token)
  }
  body$token = token

  response = httr::POST(
    url = paste0(api_url, "/translate_slide"),
    body = body,
    auth_hdr, ...)
  response
}

#' Extract content from Mario output
#'
#' @param response A `response` object, usually an output from
#' `mario` or `mario_translate`
#'
#' @return A list/`data.frame` of output
#' @export
#'
mario_content = function(response) {
  out = jsonlite::fromJSON(
    httr::content(response, as = "text"),
    flatten = TRUE)
  if ("video" %in% names(out)) {
    out$video =  mario_write_video(response)
  }
  if ("return_images" %in% names(out)) {
    if (out$return_images) {
      imgs = mario_process_images(response)
      out$full_result$images = imgs$images
      out$full_result$original_images = imgs$original_images
      rm(imgs)
    }
  }
  out$id = out$id[[1]]
  if ("subtitles" %in% names(out)) {
    out$subtitles =  mario_subtitles(response)
  }
  out
}

# Download and save a video file in the MP4 format from a HTTP response object
#' @rdname mario_content
#' @export
mario_write_video = function(response) {
  httr::stop_for_status(response)
  bin_data = httr::content(response)
  bin_data = bin_data$video[[1]]
  bin_data = base64enc::base64decode(bin_data)
  output = tempfile(fileext = ".mp4")
  writeBin(bin_data, output)
  output
}

# Write binary data stored in an R object to a temporary file with a specified file extension
bin_write = function(object, fileext) {
  tfile = tempfile(fileext = fileext)
  writeBin(object, tfile)
  return(tfile)
}

# Saves images
#' @rdname mario_content
#' @export
mario_process_images = function(response) {
  httr::stop_for_status(response)
  bin_data = httr::content(response)
  bin_data = bin_data$full_result
  if (!is.null(bin_data)) {
    if ("original_images" %in% names(bin_data)) {
      bin_data$original_images = lapply(bin_data$original_images,
                                        function(r) base64enc::base64decode(r[[1]]))
      bin_data$original_images = lapply(bin_data$original_images,
                                        bin_write, fileext = ".png")
    } else {
      bin_data$original_images = NULL
    }

    if ("original_images" %in% names(bin_data)) {
      bin_data$images = lapply(bin_data$images,
                               function(r) base64enc::base64decode(r[[1]]))
      bin_data$images = lapply(bin_data$images,
                               bin_write, fileext = ".png")
    } else {
      bin_data$images = NULL
    }
  }
  L = list()
  L$original_images = bin_data$original_images
  L$images = bin_data$images
  rm(bin_data)
  return(L)
}

# Return subtitles in character format
#' @rdname mario_content
#' @export
mario_subtitles = function(response) {
  httr::stop_for_status(response)
  bin_data = httr::content(response)
  bin_data = bin_data$subtitles[[1]]
  bin_data = base64enc::base64decode(bin_data)
  rawToChar(bin_data)
}

# Save video to MP4 and open the file immediately after it is saved
#' @rdname mario_content
#' @param open should the video be opened on the local machine?
#' @export
open_video = function(response, open = TRUE) {
  output = mario_write_video(response)
  if (open) {
    system2("open", output)
  }
  output
}
