FROM fredhutch/r-shiny-base:4.2.0

RUN apt-get --allow-releaseinfo-change update -y

RUN apt-get install -y libpoppler-cpp-dev ffmpeg
RUN apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev

RUN curl -LO https://www.python.org/ftp/python/3.9.1/Python-3.9.1.tgz
RUN tar -xf Python-3.9.1.tgz
RUN rm Python-3.9.1.tgz

WORKDIR  Python-3.9.1

RUN ./configure --enable-optimizations

RUN make -j `nproc`

RUN make altinstall

RUN python3.9 -m ensurepip

RUN python3.9 -m pip install TTS

RUN echo break cache

RUN R -e "install.packages(c('plumber', 'ariExtra', 'rmarkdown', 'animation', 'base64enc', 'pagedown', 'mime', 'testthat', 'covr', 'knitr', 'httr', 'googledrive', 'jsonlite', 'gargle', 'googlesheets4', 'remotes', 'pdftools', 'tidyr', 'text2speech', 'shinyWidgets', 'aws.polly', 'shinyjs', 'blastula', 'promises', 'future', 'ipc', 'shinyFeedback'), repos='https://cran.rstudio.com/')"

# TODO change this when PR is merged and ari is updated in CRAN:
RUN R -e 'remotes::install_github("jhudsl/text2speech", upgrade = "never")'
RUN R -e 'remotes::install_github("jhudsl/didactr", upgrade = "never")'
RUN R -e 'remotes::install_github("jhudsl/ari", "ariExtra-immigration", upgrade = "never")'



RUN mkdir -p /private/

RUN ln -s /tmp /private/



ADD . /app

WORKDIR /app

RUN R CMD INSTALL .

# make sure all packages are installed
# because R does not fail when there's an error installing a package.
RUN R -f check.R --args didactr rmarkdown plumber base64enc mime testthat covr knitr httr googledrive jsonlite remotes pdftools tidyr text2speech shinyWidgets aws.polly ari shinyjs blastula googlesheets4 gargle promises future ipc shinyFeedback mario



# ADD .secrets /app/.secrets

EXPOSE 9876


CMD R -f runAPI.R

