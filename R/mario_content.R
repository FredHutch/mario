#' Extract content from Mario output
#'
#' @param response A `response` object, usually an output from
#' `mario` or `mario_translate`
#' @param output_file A file path to where the output video should be saved.
#' 
#' @return A list/`data.frame` of output
#' @export
#'
mario_content <- function(response, output_file = NULL) {
  out <- jsonlite::fromJSON(
    httr::content(response, as = "text"),
    flatten = TRUE
  )
  if ("video" %in% names(out)) {
    out$video <- mario_write_video(response, output_file = output_file)
  }
  if ("return_images" %in% names(out)) {
    if (out$return_images) {
      imgs <- mario_process_images(response)
      out$full_result$images <- imgs$images
      out$full_result$original_images <- imgs$original_images
      rm(imgs)
    }
  }
  out$id <- out$id[[1]]
  if ("subtitles" %in% names(out)) {
    out$subtitles <- mario_subtitles(response)
  }
  out
}

#' @rdname mario_content
#' @export
mario_write_video <- function(response, output_file = NULL) {
  httr::stop_for_status(response)
  bin_data <- httr::content(response)
  
  bin_data <- bin_data$video[[1]]
  bin_data <- base64enc::base64decode(bin_data)
  
  if (is.null(output_file)) {
    # If not specified, then just call it a temporary name
    output_file <- file.path(".", "mario_video.mp4")
  } else {
    # Make it a file path
    output_file <- file.path(output_file)
    
    # Add mp4 extension if it is not there
    if (!grepl("\\.mp4$", output_file)) {
      output_file <- paste0(output_file, ".mp4")
    }
    
    # Get output directory
    output_dir <- dirname(output_file)
    
    # Create output directory if it does not exist
    if (!dir.exists(output_dir)) {
      dir.create(output_dir)
    }
  }
  writeBin(bin_data, output_file)
  
  message(paste0("Video saved to:", output_file))
}

bin_write <- function(object, fileext) {
  tfile <- tempfile(fileext = fileext)
  writeBin(object, tfile)
  return(tfile)
}

#' @rdname mario_content
#' @export
mario_process_images <- function(response) {
  httr::stop_for_status(response)
  bin_data <- httr::content(response)
  bin_data <- bin_data$full_result
  if (!is.null(bin_data)) {
    if ("original_images" %in% names(bin_data)) {
      bin_data$original_images <- lapply(
        bin_data$original_images,
        function(r) base64enc::base64decode(r[[1]])
      )
      bin_data$original_images <- lapply(bin_data$original_images,
                                         bin_write,
                                         fileext = ".png"
      )
    } else {
      bin_data$original_images <- NULL
    }
    
    if ("original_images" %in% names(bin_data)) {
      bin_data$images <- lapply(
        bin_data$images,
        function(r) base64enc::base64decode(r[[1]])
      )
      bin_data$images <- lapply(bin_data$images,
                                bin_write,
                                fileext = ".png"
      )
    } else {
      bin_data$images <- NULL
    }
  }
  L <- list()
  L$original_images <- bin_data$original_images
  L$images <- bin_data$images
  rm(bin_data)
  return(L)
}

#' @rdname mario_content
#' @export
mario_subtitles <- function(response) {
  httr::stop_for_status(response)
  bin_data <- httr::content(response)
  bin_data <- bin_data$subtitles[[1]]
  bin_data <- base64enc::base64decode(bin_data)
  rawToChar(bin_data)
}

#' @rdname mario_content
#' @param output_file A file path to where the output video should be saved.
#' @param open should the video be opened on the local machine?
#' @export
open_video <- function(response, open = TRUE, output_file = NULL) {
  output <- mario_write_video(response, output_file = output_file)
  if (open) {
    system2("open", output)
  }
  output
}