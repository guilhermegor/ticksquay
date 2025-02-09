#!/bin/bash

# define the paths
MAIN_ENV_FILE="./airflow_mktdata.env"
POSTGRES_ENV_FILE="./data/postgres_mktdata.env"

# function to append values to a file if the file doesn't exist or doesn't contain them
append_if_not_exist() {
    local file=$1
    local key=$2
    local value=$3
    # check if the key already exists in the file
    if ! grep -q "^$key=" "$file"; then
        echo "$key=$value" >> "$file"
    fi
}

# airflow_mktdata.env file setup
if [ ! -f "$AIRFLOW_ENV_FILE" ]; then
    echo "Creating airflow_mktdata.env file..."
    append_if_not_exist "$AIRFLOW_ENV_FILE" "AIRFLOW_UID" "50000"
    append_if_not_exist "$AIRFLOW_ENV_FILE" "AIRFLOW_IMAGE_NAME" "airflow-env:1.0"
    append_if_not_exist "$AIRFLOW_ENV_FILE" "_AIRFLOW_WWW_USER_USERNAME" "airflow"
    append_if_not_exist "$AIRFLOW_ENV_FILE" "_AIRFLOW_WWW_USER_PASSWORD" "PLEASE_FILL"
fi

# postgres_mktdata.env file setup
if [ ! -f "$POSTGRES_ENV_FILE" ]; then
    echo "Creating postgres_mktdata.env file..."
    append_if_not_exist "$POSTGRES_ENV_FILE" "POSTGRES_USER" "postgres"
    append_if_not_exist "$POSTGRES_ENV_FILE" "POSTGRES_PASSWORD" "PLEASE_FILL"
    append_if_not_exist "$POSTGRES_ENV_FILE" "PGADMIN_DEFAULT_EMAIL" "admin@admin.com"
    append_if_not_exist "$POSTGRES_ENV_FILE" "PGADMIN_DEFAULT_PASSWORD" "PLEASE_FILL"
fi