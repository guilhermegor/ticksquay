#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        "success") echo -e "${GREEN}[✓]${NC} ${message}" ;;
        "error") echo -e "${RED}[✗]${NC} ${message}" >&2 ;;
        "warning") echo -e "${YELLOW}[!]${NC} ${message}" ;;
        "info") echo -e "${BLUE}[i]${NC} ${message}" ;;
        "config") echo -e "${CYAN}[→]${NC} ${message}" ;;
        "debug") echo -e "${MAGENTA}[»]${NC} ${message}" ;;
        *) echo -e "[ ] ${message}" ;;
    esac
}

DB_ENV_FILE="./db_mktdata.env"
SCHEDULER_ENV_FILE="./scheduler_mktdata.env"

append_if_not_exist() {
    local file="$1"
    local key="$2"
    local value="$3"

    # check if file exists and is writable
    if [ ! -f "$file" ]; then
        touch "$file" || {
            print_status "error" "Failed to create file: $file"
            return 1
        }
    fi

    if [ ! -w "$file" ]; then
        print_status "error" "File not writable: $file"
        return 1
    fi

    # check if key exists
    if grep -q "^$key=" "$file"; then
        print_status "warning" "Key already exists in $file: $key"
        return 0
    fi

    # append the key-value pair
    echo "$key=$value" >> "$file" && {
        print_status "success" "Added $key to $file"
    } || {
        print_status "error" "Failed to write to $file"
        return 1
    }
}

print_status "info" "Starting environment file setup..."

# db_mktdata.env setup
print_status "config" "Configuring PostgreSQL environment..."
append_if_not_exist "$DB_ENV_FILE" "POSTGRES_USER" "postgres"
append_if_not_exist "$DB_ENV_FILE" "POSTGRES_PASSWORD" "postgres"
append_if_not_exist "$DB_ENV_FILE" "PGADMIN_DEFAULT_EMAIL" "admin@admin.com"
append_if_not_exist "$DB_ENV_FILE" "PGADMIN_DEFAULT_PASSWORD" "admin"

# scheduler_mktdata.env setup
print_status "config" "Configuring Airflow Scheduler environment..."
append_if_not_exist "$SCHEDULER_ENV_FILE" "AIRFLOW_UID" "50000"
append_if_not_exist "$SCHEDULER_ENV_FILE" "AIRFLOW_IMAGE_NAME" "airflow-env:1.0"
append_if_not_exist "$SCHEDULER_ENV_FILE" "_AIRFLOW_WWW_USER_USERNAME" "airflow"
append_if_not_exist "$SCHEDULER_ENV_FILE" "_AIRFLOW_WWW_USER_PASSWORD" "airflow"
append_if_not_exist "$SCHEDULER_ENV_FILE" "POSTGRES_USER" "postgres"
append_if_not_exist "$SCHEDULER_ENV_FILE" "POSTGRES_PASSWORD" "postgres"
append_if_not_exist "$SCHEDULER_ENV_FILE" "PGADMIN_DEFAULT_EMAIL" "admin@admin.com"
append_if_not_exist "$SCHEDULER_ENV_FILE" "PGADMIN_DEFAULT_PASSWORD" "admin"
append_if_not_exist "$SCHEDULER_ENV_FILE" "POSTGRES_DB" "airflow"

if [ -f "$DB_ENV_FILE" ] && [ -f "$SCHEDULER_ENV_FILE" ]; then
    print_status "success" "Environment files setup complete!"
    print_status "info" "Files created:"
    print_status "info" "- $DB_ENV_FILE"
    print_status "info" "- $SCHEDULER_ENV_FILE"
else
    print_status "error" "Some environment files failed to create"
    exit 1
fi
