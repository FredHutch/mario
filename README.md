
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mario Package:

The goal of `mario` is to automatically create videos from a set of
Google Slides. Whatever is written in the speaker notes section of the
Google Slides will be read in the video.

If you update the slides, all you need to do is re-run `mario` to update
the video.

## Installation

You can install `mario` from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("FredHutch/mario")
```

## Example

Before you can run `mario`, you will need two things:

1)  [API Key](#api-key)
2)  [Google Slides ID](#google-slides-id)

### API Key

TODO

### Google Slides ID

If you have a Google Slides set, you can obtain the Google Slides set ID
from the URL:
`https://docs.google.com/presentation/d/**presentationId**/edit`

Your [Google Slides
permissions](https://www.youtube.com/watch?v=zHSfwaZIVbM) must be set to
`Anyone with the link`. For testing purposes, we’ve included a set of
[test
slides](https://docs.google.com/presentation/d/1sFsRXfK7LKxFm-ydib5dxyQU9fYujb95katPRu0WVZk/edit#slide=id.p)
you can use to practice.

## Running Mario

``` r
# Google Slides ID
id <- "1sFsRXfK7LKxFm-ydib5dxyQU9fYujb95katPRu0WVZk"

# Run mario!
res <- mario::mario(id,
  voice = "en-US-Wavenet-F")

# Write the video
mario::mario_write_video(
  res)
```

Mario will print a file path to the newly rendered video in the console.
If you’d like to see a list of all the voice options:

``` r
voice_options <- mario_voices()
head(voice_options)
```
