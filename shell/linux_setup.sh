#!/bin/bash

# source the .env file to load environment variables
#   automatically export all variables
set -a
sed -i 's/\r$//' airflow_mktdata.env
source airflow_mktdata.env
set +a 

# create the airflow user if it doesn't exist
useradd -m -d /home/airflow airflow

# set the owner of the files in AIRFLOW_PROJ_DIR to the user 
mkdir -p ${AIRFLOW_PROJ_DIR}
chown -R airflow: ${AIRFLOW_PROJ_DIR}

# install linux dependencies and tools
apt-get update -yqq && \
    apt-get upgrade -yqq && \
    apt-get install -yqq --no-install-recommends \ 
    wget \
    libczmq-dev \
    curl \
    libssl-dev \
    git \
    inetutils-telnet \
    bind9utils freetds-dev \
    libkrb5-dev \
    libsasl2-dev \
    libffi-dev libpq-dev \
    freetds-bin build-essential \
    default-libmysqlclient-dev \
    apt-utils \
    rsync \
    zip \
    unzip \
    gcc \
    vim \
    locales \
    docker \
    tree \
    && apt-get clean

# create required directories if they don't exist
mkdir -p ./dags ./logs ./plugins ./config