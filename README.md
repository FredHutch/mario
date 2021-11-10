
[![Travis build
status](https://travis-ci.com/jhudsl/ariExtra.svg?branch=master)](https://travis-ci.com/jhudsl/ariExtra)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/jhudsl/ariExtra?branch=master&svg=true)](https://ci.appveyor.com/project/jhudsl/ariExtra)
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mario Package:

The goal of `mario` is to create automatically create videos from Google slides.

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

### Get the API Key

You will need access to the mario RSConnect and you'll need to obtain an API token.
Click on your profile in the upper right corner > `API Keys` > `+ New API Key` and copy that API key token.

### Get your Google Slide ID

If you have a google slide set, you can obtain the google slide set ID from the URL:
`https://docs.google.com/presentation/d/**presentationId**/edit`

## Running Mario

``` r
# Google slide ID
id <- "presentation-Id"

res <- mario::mario(id,
  voice = "en-US-Wavenet-F",
  api_key = "your-api-key")

mario::mario_write_video(res, api_url = "https://rsconnect.biostat.jhsph.edu/mario/")
```
