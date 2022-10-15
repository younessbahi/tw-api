FROM rocker/r-ver:4.0.5

RUN apt-get update -qq && apt-get install -y \
    libssl-dev \
    git-core \
    libssl-dev \
    libcurl4-gnutls-dev \
    curl \
    libsodium-dev \
    libxml2-dev \
    gcc \
    gsl-bin \
    libblas-dev \
    chromium-browser

# install pkgs
RUN R -e "install.packages('plumber', dependencies = TRUE)"
RUN R -e "install.packages('tidyverse', dependencies = TRUE)"
RUN R -e "install.packages('magrittr', dependencies = TRUE)"
RUN R -e "install.packages('operator.tools', dependencies = TRUE)"
RUN R -e "install.packages('https://packagemanager.rstudio.com/all/latest/src/contrib/chromote_0.1.1.tar.gz', type = 'source')"
RUN R -e "install.packages('httr', dependencies = TRUE)"
RUN R -e "install.packages('glue', dependencies = TRUE)"
RUN R -e "install.packages('future', dependencies = TRUE)"
RUN R -e "install.packages('rlist', dependencies = TRUE)"
RUN R -e "install.packages('urltools', dependencies = TRUE)"
RUN R -e "install.packages('na.tools', dependencies = TRUE)"
RUN R -e "install.packages('pacman', dependencies = TRUE)"
RUN R -e "chromote::set_chrome_args(c('--disable-gpu', '--disable-dev-shm-usage', '--no-sandbox'))"


COPY / /app
WORKDIR /app
EXPOSE 80
CMD ["Rscript", "main.R"]