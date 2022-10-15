FROM rocker/r-ver:4.0.5


RUN apt-get update -qq && apt-get install -y \
    libssl-dev \
    git-core \
    libssl-dev \
    libcurl4-gnutls-dev \
    curl \
.
    libxml2-dev \
    gcc \
    gsl-bin \
    libblas-dev \
    chromium-browser \
    gnupg2

## try to install chromote_chrome
RUN apt-get install -y wget
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get install -y ./google-chrome-stable_current_amd64.deb

# install pkgs
RUN R -e "install.packages('remotes', dependencies = TRUE)"
RUN R -e "install.packages('plumber', dependencies = TRUE)"
RUN R -e "install.packages('tidyverse', dependencies = TRUE)"
RUN R -e "install.packages('magrittr', dependencies = TRUE)"
RUN R -e "install.packages('operator.tools', dependencies = TRUE)"
RUN R -e "remotes::install_github('https://github.com/rstudio/chromote')"
RUN R -e "install.packages('httr', dependencies = TRUE)"
RUN R -e "install.packages('glue', dependencies = TRUE)"
RUN R -e "install.packages('future', dependencies = TRUE)"
RUN R -e "install.packages('rlist', dependencies = TRUE)"
RUN R -e "install.packages('urltools', dependencies = TRUE)"
RUN R -e "install.packages('na.tools', dependencies = TRUE)"
RUN R -e "install.packages('pacman', dependencies = TRUE)"

COPY / /app
WORKDIR /app
EXPOSE 80
CMD ["Rscript", "main.R"]