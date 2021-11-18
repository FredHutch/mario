
[![Travis build
status](https://travis-ci.com/jhudsl/ariExtra.svg?branch=master)](https://travis-ci.com/jhudsl/ariExtra)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/jhudsl/ariExtra?branch=master&svg=true)](https://ci.appveyor.com/project/jhudsl/ariExtra)
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mario Package:

The goal of `mario` is to create automatically create videos from a Google slides.
Whatever is written in the speaker notes section of the Google slides will be read in the video.

If you update the slides, all you need to do is re-run `mario` to update the video.

## Installation

You can install `mario` from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("jhudsl/mario")
```

## Example

Before you can run `mario`, you will need two things:
1) An API Key and
2) Your Google slide ID that you'd like to translate into a video.

### Get and set the API Key

You will need access to the mario RSConnect and you'll need to obtain an API token.
Click on your profile in the upper right corner > `API Keys` > `+ New API Key` and copy that API key token.

In your local RStudio copy your API key in a command like this and run it:
```
Sys.setenv(CONNECT_API_KEY = "your-api-key")
```
Now the API Key is stored in `~/.Renviron` as a hidden file.

You should only need to do this once per your RStudio environment.
For now, the Mario API Key is stored in `~/.Renviron` as a hidden file.
It is called `CONNECT_API_KEY`. You can call it something else, but this is the name that the api key functions below use by default, e.g.:

`mario_auth(api_key = Sys.getenv("CONNECT_API_KEY"))`


Now to test if your API key has been set up correctly, run this:
```
if (mario_have_api_key()) {
  mario_api_key()
}
```
If it is set up correctly, if should repeat back to you your API key.

### Get your Google Slide ID

If you have a google slide set, you can obtain the google slide set ID from the URL:
`https://docs.google.com/presentation/d/**presentationId**/edit`

Your [Google slides permissions](https://artofpresentations.com/give-permissions-on-google-slides/) must be set to `Anyone with link can view`
For testing purposes, we've included a set of [test slides](https://docs.google.com/presentation/d/1sFsRXfK7LKxFm-ydib5dxyQU9fYujb95katPRu0WVZk/edit#slide=id.p) you can use to practice.

## Running Mario

```{r}
# Google slide ID
id <- "1sFsRXfK7LKxFm-ydib5dxyQU9fYujb95katPRu0WVZk"

# Run mario!
res <- mario::mario(id,
  voice = "en-US-Wavenet-F")

# Write the video
mario::mario_write_video(
  res
  file = file.path())
```

If you'd like to see a list of all the voice options:

```{r}
voice_options <- mario_voices()
head(voice_options)
```
