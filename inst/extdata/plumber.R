#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#

library(plumber)
library(ari)
library(didactr)
library(ariExtra)
library(rmarkdown)
library(animation) #need for ffmpeg
library(base64enc)
library(pagedown)
library(mime)
Sys.setenv(GL_AUTH = "google_authorization.json")

# required for any the error
# libreglo.so: cannot open shared object file:
LD_LIBRARY_PATH = Sys.getenv("LD_LIBRARY_PATH")
Sys.setenv(
  LD_LIBRARY_PATH=
    paste0(
      "/usr/lib/libreoffice/program",
      if (nzchar(LD_LIBRARY_PATH)) paste0(":", LD_LIBRARY_PATH)
    )
)

# way to get around "uploading" multiple files
# SHOULD REWRITE FOR ALL OF THIS
convert_images = function(contents) {
  file = contents$file
  nc = 0
  if (is.character(file)) {
    nc = nchar(file)
  }
  if (!is.data.frame(file) & nc > 1000) {
    file = strsplit(file, split = "\n")[[1]]
    # getting the type
    type = sub("^(.*): .*", "\\1", file)
    file = sub("^(.*): (.*)", "\\2", file)
    file = mapply(
      function(x, ext) {
        tfile = tempfile(fileext = paste0(".", ext))
        out = base64enc::base64decode(x)
        writeBin(out, con = tfile)
        tfile
      }, file, type)
    file = unname(file)
    file = data.frame(
      datapath = file,
      type = paste0("image/", type),
      name = basename(file),
      stringsAsFactors = FALSE)
    contents$file = file
  }
  contents
}

unzipper = function(file) {
  if (is.character(file)) {
    return(file)
  }
  type = file$type
  btype = tolower(basename(type))
  if (is.data.frame(file)) {
    if (nrow(file) == 1 &&
        btype %in% "zip") {
      message("Unzipping the files")
      outfiles =  unzip(
        file$datapath,
        exdir = tempdir(),
        list = TRUE,
        overwrite = TRUE)$Name
      unzip(
        file$datapath,
        exdir = tempdir(),
        overwrite = TRUE)
      outfiles = file.path(
        tempdir(),
        outfiles)
      print(outfiles)
      file = data.frame(
        name = basename(outfiles),
        size = file.size(outfiles),
        datapath = outfiles,
        type = mime::guess_type(outfiles),
        stringsAsFactors = FALSE)
    }
  }
  return(file)
}


#' @examples
#' library(httr)
#' file = system.file("extdata", "example.pdf", package = "ariExtra")
#' tfile = tempfile()
#' script = c("hey", "ho")
#' writeLines(script, tfile)
#'
#' api_url = "http://127.0.0.1:4892"
#' POST(paste0(api_url, "/to_video"),
#'    body = list(file = upload_file(file), script = upload_file(tfile)))
name_contents = function(req) {
  # print("req is this!")
  # print(req)
  contents = mime::parse_multipart(req)
  arg_names = c("file", "script", "voice",
                "service", "subtitles", "token",
                "trash", "target")
  contents_names = names(contents)
  print(arg_names)
  named_contents = contents[contents_names %in% arg_names ]
  contents = contents[!names(contents) %in% arg_names]
  n_contents = seq_along(contents)


  names(contents) = setdiff(arg_names, contents_names)[n_contents]
  contents = c(named_contents, contents)

  print("Running unzipper")
  contents$file = unzipper(contents$file)
  # way to get around "uploading" multiple files
  print("here are before content")
  print(contents)

  contents = convert_images(contents)
  print("here are the contents from name_contents")

  voice = contents$voice
  service = contents$service
  if (is.null(service)) {
    # service = "amazon"
    service = "google"
  }


  if (!text2speech::tts_auth(service = service)) {
    stop(paste0("Service ", service, " not authorized yet"))
  }
  if (is.null(voice)) {
    voice = text2speech::tts_default_voice(service = service)
  }
  contents$voice = voice
  contents$service = service
  contents$subtitles = ifelse(
    is.null(contents$subtitles),
    TRUE,
    as.logical(contents$subtitles))

  return(contents)
}

guess_ari_func = function(contents, verbose = TRUE) {
  file = contents$file
  if (!is.data.frame(file)) {
    if (verbose) {
      print("gs")
    }
    func_name = ariExtra::gs_to_ari
    attr(func_name, "type") = "gs"

  } else {
    type = file$type
    btype = tolower(basename(type))
    if (all(btype %in% c("png", "jpg", "jpeg", "gif"))) {
      if (verbose) {
        print("png")
      }
      func_name = ariExtra::images_to_ari
      attr(func_name, "type") = "png"
    }
    if (all(btype %in% c("html"))) {
      if (verbose) {
        print("html")
      }
      func_name = ariExtra::html_to_ari
      attr(func_name, "type") = "html"
    }
    if (btype %in% "pdf") {
      if (verbose) {
        print("pdf")
      }
      func_name = ariExtra::pdf_to_ari
      attr(func_name, "type") = "pdf"

    }
    if (any(grepl("officedocument.presentation", btype))) {
      if (verbose) {
        print("pptx")
      }
      func_name = ariExtra::pptx_to_ari
      attr(func_name, "type") = "pptx"
    }
    # func_name = "mp4_to_ari"

    # func_name = "rmd_to_ari"
    # func_name = "mp4_to_ari"
  }

  # use do.call
  return(func_name)

}

#* @apiTitle Presentation Video Generation API

#* Process Input into a Video
#* @param target target language to translate to. If this is passed, then translation is done.
#* @param service service to use for voice synthesis, including "amazon", "google", or "microsoft".  Currently only "google" supported
#* @param voice The voice to use for synthesis, needs to be paired with service
#* @param script file upload of script
#* @param file ID of Google Slide deck, or file upload of PDF slides, PPTX file, or list of PNGs
#* @post /to_ari
function(req) {

  # stop("Not ready")
  contents = name_contents(req)
  print("contents")
  print(contents)
  func_to_run = guess_ari_func(contents, verbose = TRUE)
  type_out = attr(func_to_run, "type")
  attr(func_to_run, "type") = NULL
  print("func_to_run")
  # print(func_to_run)
  file = contents$file
  print("file")
  print(file)
  script = contents$script
  print(script)
  voice = contents$voice
  service = contents$service
  subtitles = contents$subtitles

  target = contents$target
  translation = NULL
  if (!is.null(target)) {
    translation = run_translation(contents)
    file = translation$id
    type_out = "gs"
  }

  if (is.null(type_out) || !type_out %in% "gs") {
    file = file$datapath
  }
  if (type_out %in% "pptx") {
    # need this for docxtractr
    if (!docxtractr:::is_pptx(file)) {
      tmpfile = file
      file = paste0(tmpfile, ".pptx")
      file.copy(tmpfile, file)
      print("pptx was copied")
    }
    print(file.exists(file))
    print(file.info(file))
  }
  script = script$datapath

  cat(file)
  cat(script)
  args = list(path = file, script = script)
  args$service = service
  args$voice = voice
  args$open = FALSE
  args$verbose = 2
  args$subtitles = subtitles
  print("args")
  print(args)
  res = do.call(func_to_run, args = args)
  # res = func_to_run(file, script = script,
  #                   open = FALSE)
  ##* @serializer contentType list(type="video/mp4")
  video = ari_processor(
    res,
    voice = voice, service = service,
    subtitles = subtitles)
  subtitles = video$subtitles
  video = video$video
  L = list(
    video = video,
    subtitles = subtitles,
    full_result = res,
    result = TRUE
  )
  L$translation = translation
  L
}


#* List Voices
#* @param service service to use for voice synthesis, including "amazon", "google", or "microsoft".  Currently only "google" supported
#* @get /list_voices
function(service = NULL) {

  if (is.null(service)) {
    service = "google"
  }
  text2speech::tts_auth(service = service)
  return(text2speech::tts_voices(service = service))
}


ari_processor = function(res, voice, service, subtitles) {
  doc_args = list(verbose = TRUE)
  doc_args$voice = voice
  doc_args$service = service
  doc_args$subtitles = subtitles
  format = do.call(ariExtra::ari_document, args = doc_args)

  out = rmarkdown::render(res$output_file, output_format = format)
  output = output_movie_file
  sub_file = paste0(tools::file_path_sans_ext(output), ".srt")
  if (!file.exists(output)) {
    stop("Video was not generated")
  }
  # readBin(output, "raw", n = file.info(output)$size)
  list(
    subtitles = base64enc::base64encode(sub_file),
    video = base64enc::base64encode(output)
  )
}

#* @apiTitle Presentation Video Generation API

#* Translates a Google Slide Deck Into Another Language
#* @param file ID of Google Slide deck
#* @param trash should the slide deck be trashed?
#* @param target target language to translate to.
#* @param token token file upload for Google Drive
#* @post /translate_slide
function(req) {

  contents = name_contents(req)
  print("contents")
  print(contents)
  L = run_translation(contents)

  return(L)
}

run_translation = function(contents) {

  target = contents$target
  print("target")
  print(target)
  if (is.null(target)) {
    stop("target required for translate_slide")
  }

  func_to_run = guess_ari_func(contents, verbose = 2)
  type_out = attr(func_to_run, "type")
  attr(func_to_run, "type") = NULL
  print("func_to_run")
  if (!type_out %in% c("gs", "pptx")) {
    stop(
      paste0(
        "Only Google Slide ID or PPTX allowed. Upload document ",
        "to Google Slides and use slide ID")
    )
  }

  token = contents$token
  if (is.null(token)) {
    stop("Token required for translate_slide")
  }
  if ("datapath" %in% names(token)) {
    token = token$datapath
  }
  token = readRDS(token)

  file = contents$file
  print("file")
  print(file)

  didactr::check_didactr_auth(token = token)
  gs_name = basename(tempfile())
  if (type_out %in% "pptx") {
    file = didactr::pptx_to_gs(path = file)$id
  }

  result = didactr::copy_and_translate_slide(
    id = file,
    gs_name = NULL,
    verbose = 2,
    share = TRUE,
    trash_same_gs_name = FALSE,
    target = target)

  contents$token = NULL
  L = list(
    id = result$id,
    result = result,
    file = file,
    contents = contents)
}


#* Base Handler that Gives a list of endpoints
#* @get /endpoints
function() {
  list(
    "translate_slide" =
      list(
        description = "Translates a Google Slide Deck Into Another Language",
        params = list(
          token = "Google Drive token file, passed to httr::upload_file",
          file = "Google Slide ID or httr::upload_file of PPTX",
          trash = 'should the slide deck be trashed after copying and translating?',
          target = 'target language to translate to.'
        )
      ),
    "to_ari" =
      list(
        description ="Process a Number of Different Inputs into a Video",
        params = list(
          target = 'target language to translate to. If this is passed, then translation is done.',
          service = paste0(
            'service to use for voice synthesis, including ',
            '"amazon", "google", or "microsoft".  Currently only ',
            '"google" supported'),
          voice = 'The voice to use for synthesis, needs to be paired with service',
          script = 'file upload of script, in body passed to httr::upload_file',
          file = 'ID of Google Slide deck, or file upload of PDF slides, PPTX file, or list of PNGs',
          token = "Google Drive token file, passed to httr::upload_file",
          file = "Google Slide ID or httr::upload_file of PPTX"
        )
      ),
    "list_voices" = list(
      description =
        "List the Available Voices for a Text-to-Speech Service",
      params = list(
        service = paste0(
          'service to use for voice synthesis, including ',
          '"amazon", "google", or "microsoft".  Currently only ',
          '"google" supported')
      )
    )
  )
}
