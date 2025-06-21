#!/bin/bash

# Color palette for logging
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

# Function to create backup directory
create_backup_dir() {
    BACKUP_DIR="backup/$(date +'%Y%m%d_%H%M%S')"
    mkdir -p "$BACKUP_DIR"
    print_status "info" "Created backup directory: $BACKUP_DIR"
}

# Function to validate and set Airflow version
set_airflow_version() {
    AIRFLOW_VERSION=$1
    if [[ ! $AIRFLOW_VERSION =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        print_status "error" "Invalid version format. Please use format X.Y.Z or X.Y"
        exit 1
    fi
    print_status "success" "Using Airflow version ${AIRFLOW_VERSION}"
}

# Function to check Python version and determine compatible Airflow version
check_python_compatibility() {
    PYTHON_MINOR=$(python -c "import sys; print(sys.version_info.minor)")
    PYTHON_MAJOR=$(python -c "import sys; print(sys.version_info.major)")

    if [[ $PYTHON_MAJOR -eq 3 ]]; then
        if [[ $PYTHON_MINOR -ge 12 ]]; then
            # Python 3.12+ only compatible with Airflow 3.0+
            if [[ ! $AIRFLOW_VERSION =~ ^3\. ]]; then
                print_status "error" "Python 3.12+ requires Airflow 3.0+, but got ${AIRFLOW_VERSION}"
                exit 1
            fi
            AIRFLOW_CONSTRAINT=">=3.0.0"
        else
            # Python 3.9-3.11 compatible with Airflow 2.7+
            if [[ $AIRFLOW_VERSION =~ ^3\. ]]; then
                print_status "warning" "Airflow 3.0+ is compatible with Python 3.12+, but using Python 3.${PYTHON_MINOR}"
            fi
            AIRFLOW_CONSTRAINT=">=2.7.3"
        fi
    else
        print_status "error" "Unsupported Python major version: ${PYTHON_MAJOR}"
        exit 1
    fi
}

update_docker_compose() {
    local url="https://airflow.apache.org/docs/apache-airflow/${AIRFLOW_VERSION}/docker-compose.yaml"
    print_status "info" "Downloading Airflow ${AIRFLOW_VERSION} docker-compose file from ${url}"

    if curl -s -f "$url" > /tmp/airflow-docker-compose.yaml; then
        if [ -f "airflow_docker-compose.yml" ]; then
            cp airflow_docker-compose.yml "${BACKUP_DIR}/airflow_docker-compose.yml.bak"
            print_status "info" "Backed up existing docker-compose file to ${BACKUP_DIR}"
        fi

        {
            awk '/^[^#]/ {exit} {print}' /tmp/airflow-docker-compose.yaml
            echo "name: mktdata_scheduler"
            echo ""
            awk '/^[^#]/ {p=1} p' /tmp/airflow-docker-compose.yaml
        } > /tmp/airflow-docker-compose-modified.yaml

        # Modify the AIRFLOW__CORE__LOAD_EXAMPLES setting
        if grep -q "AIRFLOW__CORE__LOAD_EXAMPLES" /tmp/airflow-docker-compose-modified.yaml; then
            sed -i "s/AIRFLOW__CORE__LOAD_EXAMPLES: 'true'/AIRFLOW__CORE__LOAD_EXAMPLES: 'false'/" /tmp/airflow-docker-compose-modified.yaml
            print_status "success" "Changed AIRFLOW__CORE__LOAD_EXAMPLES to false"
        else
            # Add the setting if it doesn't exist (find the x-airflow-common section)
            sed -i '/x-airflow-common:/a \      environment: &airflow_common_environment\n        AIRFLOW__CORE__LOAD_EXAMPLES: "false"' /tmp/airflow-docker-compose-modified.yaml
            print_status "info" "Added AIRFLOW__CORE__LOAD_EXAMPLES: false to environment"
        fi

        mv /tmp/airflow-docker-compose-modified.yaml airflow_docker-compose.yml
        print_status "success" "Updated airflow_docker-compose.yml for version ${AIRFLOW_VERSION}"
    else
        print_status "error" "Failed to download docker-compose file"
        exit 1
    fi
}

# Function to update Dockerfile
update_dockerfile() {
    PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

    if [ -f "airflow-env_dockerfile" ]; then
        cp airflow-env_dockerfile "${BACKUP_DIR}/airflow-env_dockerfile.bak"
        print_status "info" "Backed up existing Dockerfile to ${BACKUP_DIR}"

        sed -i "s|FROM apache/airflow:slim-[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?-python[0-9]\+\.[0-9]\+|FROM apache/airflow:slim-${AIRFLOW_VERSION}-python${PYTHON_VERSION}|" airflow-env_dockerfile
        print_status "success" "Updated Dockerfile to use Airflow ${AIRFLOW_VERSION} with Python ${PYTHON_VERSION}"
    else
        print_status "error" "airflow-env_dockerfile not found"
        exit 1
    fi
}

# Function to install requirements
install_requirements() {
    if [ -f "requirements.txt" ]; then
        print_status "info" "Installing dependencies from requirements.txt"
        if python -m pip install -r requirements.txt; then
            print_status "info" "Installed packages:\n$(python -m pip list)"
            print_status "success" "Dependencies installed successfully"
        else
            print_status "error" "Failed to install requirements"
            exit 1
        fi
    else
        print_status "warning" "requirements.txt not found"
    fi
}

# Function to update Poetry dependencies with version-specific constraints
update_poetry_dependencies() {
    # Verify poetry is available
    if ! python -m poetry --version >/dev/null 2>&1; then
        print_status "error" "Poetry not found. Please ensure it's included in requirements.txt"
        exit 1
    fi

    # Update dependencies
    print_status "info" "Updating dependencies..."
    if python -m poetry update; then
        print_status "success" "Dependencies updated"
    else
        print_status "error" "Failed to update dependencies"
        exit 1
    fi

    # Generate lock file
    print_status "info" "Generating lock file..."
    if python -m poetry lock; then
        print_status "success" "Lock file generated"
    else
        print_status "error" "Failed to generate lock file"
        exit 1
    fi
}

# Main function
main() {
    if [ -z "$1" ]; then
        print_status "error" "Airflow version argument required"
        print_status "info" "Usage: $0 <AIRFLOW_VERSION>"
        exit 1
    fi

    print_status "info" "Starting Airflow configuration update"

    create_backup_dir
    set_airflow_version "$1"
    check_python_compatibility
    update_docker_compose
    update_dockerfile

    # Install all requirements (including poetry)
    install_requirements

    # Update poetry dependencies with version-specific constraints
    update_poetry_dependencies

    print_status "success" "Configuration update completed"
    print_status "info" "Backups stored in: $BACKUP_DIR"
}

# Execute
main "$1"
