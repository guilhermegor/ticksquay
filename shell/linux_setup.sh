#!/bin/bash

# set default values if variables are unset or empty
USER=${USER:-airflow}
AIRFLOW_UID=${AIRFLOW_UID:-50000}

# check wheter the user already exists, drop it and recreate
if id -u ${USER} &>/dev/null; then \
    echo "User ${USER} already exists, removing it..."; \
    userdel -r ${USER}; \
    fi

# check wheter the UID already exists, drop it and recreate
if getent passwd ${AIRFLOW_UID} &>/dev/null; then \
    echo "UID ${AIRFLOW_UID} already exists, removing it..."; \
    userdel -r $(getent passwd ${AIRFLOW_UID} | cut -d: -f1); \
    fi

# create a new user with the specified UID
useradd -m -u ${AIRFLOW_UID} -g root ${USER} && \
    chown -R ${USER}:root /opt/airflow

# install dependencies
apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    python3-distutils \
    libpq-dev \
    gcc \
    cython3 \
    libyaml-dev \
    liblapack-dev \
    libblas-dev \
    unixodbc-dev \
    freetds-dev \
    g++ \
    python3-setuptools \
    libssl-dev \
    libffi-dev \
    libsasl2-dev \
    libcurl4-openssl-dev \
    wget \
    tar \
    make \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    zlib1g-dev \
    libsuitesparse-dev \
    libodbc1 \
    odbcinst \
    odbcinst1debian2 \
    libicu-dev \
    liblzma-dev
