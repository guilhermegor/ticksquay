#!/bin/bash

# =============================================
# TEST MATRIX CONFIGURATION
# =============================================
# PYTHON VERSIONS TO TEST:
PYTHON_VERSIONS=(
  "3.9.22"
  "3.10.17"
  "3.11.12"
  "3.12.8"
)

# AIRFLOW VERSIONS TO TEST:
AIRFLOW_VERSIONS=(
  "2.7.3"
  "2.8.4"
  "2.9.3"
  "2.10.5"
  "2.11.0"
  "3.0.2"
)
# =============================================

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

# Function to check if an error is critical or just a warning
is_critical_error() {
    local log_output="$1"
    # Define patterns that indicate warnings (non-critical)
    local warning_patterns=(
        "level=warning"
        "WARNING:"
        "DeprecationWarning"
        "is deprecated"
        "will be removed"
        "not found, but"
        "the attribute .* is obsolete"
        "it will be ignored"
        "please remove it"
        "to avoid potential confusion"
        "\[notice\]"
        "pip upgrade"
    )

    # If there's no output, assume success
    if [[ -z "$log_output" ]]; then
        return 1
    fi

    # Check for critical error patterns
    if grep -q -E "ERROR:|CRITICAL:|failed|error:|exception|command not found|Erro [0-9]" <<< "$log_output"; then
        # But exclude known warning patterns even if they contain "error" or "warning"
        for pattern in "${warning_patterns[@]}"; do
            if grep -q "$pattern" <<< "$log_output"; then
                return 1  # It's just a warning
            fi
        done
        return 0  # It's a critical error
    fi

    return 1  # Default to non-critical if no error patterns found
}

# Modified compose stack execution with warning-tolerant error handling
run_compose_stack_with_warnings() {
    local tmp_log=$(mktemp)
    local test_header="$1"

    print_status "info" "Running compose stack (tolerating warnings)"

    # Run the command and capture all output
    make run_compose_stack_no_cache >> "$tmp_log" 2>&1
    local exit_code=$?

    # Save output to main log
    cat "$tmp_log" >> "${MAIN_LOG}"

    # Check if there are any critical errors
    if [[ $exit_code -ne 0 ]] || is_critical_error "$(cat "$tmp_log")"; then
        ERROR_MSG="${test_header} Failed to run compose stack (critical error)"
        print_status "error" "${ERROR_MSG}"
        echo "${ERROR_MSG}" >> "${ERROR_LOG}"

        # Capture relevant logs
        {
            echo ""
            echo "=== ERROR DETAILS ==="
            echo "${ERROR_MSG}"
            echo "Exit code: $exit_code"
            echo ""
            echo "=== LAST 20 LINES OF OUTPUT ==="
            tail -n 20 "$tmp_log"
            echo ""
            echo "=== DOCKER LOGS ==="
            docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml logs >> "${ERROR_LOG}" 2>&1
        } >> "${ERROR_LOG}"

        rm "$tmp_log"
        return 1
    else
        # Check if there were any warnings (non-critical)
        if grep -q -E "WARNING:|Warning:|DeprecationWarning|level=warning|notice" "$tmp_log"; then
            WARNING_MSG="${test_header} Compose stack completed with warnings"
            print_status "warning" "${WARNING_MSG}"
            {
                echo ""
                echo "=== WARNING DETAILS ==="
                echo "${WARNING_MSG}"
                echo ""
                echo "=== WARNING OUTPUT ==="
                grep -E "WARNING:|Warning:|DeprecationWarning|level=warning|notice" "$tmp_log" | sort | uniq
                echo ""
            } >> "${MAIN_LOG}"
        else
            print_status "success" "Compose stack started successfully for ${test_header}"
        fi

        rm "$tmp_log"
        return 0
    fi
}

# Store original Python version
ORIGINAL_PYTHON_VERSION=$(pyenv local)
print_status "info" "Original Python version: ${ORIGINAL_PYTHON_VERSION}"

# Create logs directory if it doesn't exist
mkdir -p logs

# Get current timestamp for log files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MAIN_LOG="logs/full-airflow-matrix-versions-testing_${TIMESTAMP}.log"
ERROR_LOG="logs/errors-airflow-matrix-versions-testing_${TIMESTAMP}.log"

# Log header with test matrix configuration
{
  echo "============================================="
  echo " AIRFLOW MATRIX TEST RUN - ${TIMESTAMP}"
  echo "============================================="
  echo ""
  echo "ORIGINAL PYTHON VERSION: ${ORIGINAL_PYTHON_VERSION}"
  echo "PYTHON VERSIONS: ${PYTHON_VERSIONS[*]}"
  echo "AIRFLOW VERSIONS: ${AIRFLOW_VERSIONS[*]}"
  echo ""
  echo "============================================="
  echo ""
} > "${MAIN_LOG}"

# Error log header
{
  echo "============================================="
  echo " AIRFLOW MATRIX TEST ERRORS - ${TIMESTAMP}"
  echo "============================================="
  echo ""
  echo "ORIGINAL PYTHON VERSION: ${ORIGINAL_PYTHON_VERSION}"
  echo "PYTHON VERSIONS: ${PYTHON_VERSIONS[*]}"
  echo "AIRFLOW VERSIONS: ${AIRFLOW_VERSIONS[*]}"
  echo ""
  echo "============================================="
  echo ""
} > "${ERROR_LOG}"

# Function to handle pyenv version setup
setup_python_version() {
    local py_version=$1
    local attempts=0
    local max_attempts=2

    while [[ $attempts -lt $max_attempts ]]; do
        print_status "info" "Setting Python version to ${py_version} (Attempt $((attempts+1)))"

        # Check if version is installed
        if ! pyenv versions | grep -q "${py_version}"; then
            print_status "warning" "Python ${py_version} not installed. Installing..."
            if pyenv install "${py_version}"; then
                print_status "success" "Python ${py_version} installed successfully"
            else
                print_status "error" "Failed to install Python ${py_version}"
                ((attempts++))
                continue
            fi
        fi

        # Set local version
        if pyenv local "${py_version}"; then
            print_status "success" "Python version set to ${py_version}"
            return 0
        else
            print_status "error" "Failed to set Python version to ${py_version}"
            ((attempts++))
        fi
    done

    print_status "error" "Max attempts reached for Python version ${py_version}"
    return 1
}

# Function to change Airflow version
change_airflow_version() {
    local af_version=$1
    print_status "info" "Changing Airflow version to ${af_version}"

    if ! make airflow_change_tag AIRFLOW_VERSION="${af_version}" >> "${MAIN_LOG}" 2>&1; then
        print_status "error" "Failed to change Airflow version to ${af_version}"

        # Capture detailed error from the log
        local last_error=$(tail -n 10 "${MAIN_LOG}")
        {
            echo ""
            echo "=== ERROR DETAILS ==="
            echo "${last_error}"
            echo ""
        } >> "${ERROR_LOG}"

        return 1
    fi

    print_status "success" "Airflow version changed to ${af_version}"
    return 0
}

# Function to clean up Docker environment
cleanup_docker() {
    print_status "info" "Cleaning up Docker environment"
    docker compose --env-file airflow_mktdata.env -f airflow_docker-compose.yml down -v --remove-orphans >> "${MAIN_LOG}" 2>&1
    docker system prune -f >> "${MAIN_LOG}" 2>&1
}

# Main test loop
for py_version in "${PYTHON_VERSIONS[@]}"; do
    for af_version in "${AIRFLOW_VERSIONS[@]}"; do
        TEST_HEADER="[PYTHON:${py_version} | AIRFLOW:${af_version}]"

        # Print colorful header for console
        echo -e "\n${MAGENTA}=============================================${NC}"
        echo -e "${MAGENTA} TESTING: ${CYAN}Python ${py_version} ${MAGENTA}with ${CYAN}Airflow ${af_version}${NC}"
        echo -e "${MAGENTA}=============================================${NC}\n"

        # Log header for files
        {
          echo ""
          echo "============================================="
          echo "TESTING: Python ${py_version} with Airflow ${af_version}"
          echo "============================================="
          echo ""
        } >> "${MAIN_LOG}"

        print_status "config" "Starting test ${TEST_HEADER}"

        # Clean up Docker environment before starting new test
        cleanup_docker

        # Set Python version
        if ! setup_python_version "${py_version}"; then
            ERROR_MSG="${TEST_HEADER} Failed to set Python version"
            print_status "error" "${ERROR_MSG}"
            echo "${ERROR_MSG}" >> "${ERROR_LOG}"
            continue
        fi

        # Change Airflow version
        if ! change_airflow_version "${af_version}"; then
            ERROR_MSG="${TEST_HEADER} Failed to change Airflow version"
            print_status "error" "${ERROR_MSG}"
            echo "${ERROR_MSG}" >> "${ERROR_LOG}"
            continue
        fi

        # Run compose stack with warning-tolerant error handling
        if ! run_compose_stack_with_warnings "${TEST_HEADER}"; then
            # Only cleanup and continue if we want to stop on critical errors
            cleanup_docker
            continue
        fi

        # Clean up after successful or failed test
        cleanup_docker

        print_status "success" "Completed test ${TEST_HEADER}"
    done
done

# Restore original Python version
print_status "info" "Restoring original Python version: ${ORIGINAL_PYTHON_VERSION}"
pyenv local "${ORIGINAL_PYTHON_VERSION}"
if [ $? -eq 0 ]; then
    print_status "success" "Successfully restored Python version to ${ORIGINAL_PYTHON_VERSION}"
else
    print_status "error" "Failed to restore Python version to ${ORIGINAL_PYTHON_VERSION}"
    echo "Failed to restore Python version to ${ORIGINAL_PYTHON_VERSION}" >> "${ERROR_LOG}"
fi

# Final summary
print_status "info" "All tests completed."
print_status "info" "Full log: ${MAIN_LOG}"
print_status "info" "Error log: ${ERROR_LOG}"

# Log completion timestamp
{
  echo ""
  echo "============================================="
  echo " TESTING COMPLETED AT: $(date)"
  echo "ORIGINAL PYTHON VERSION RESTORED: ${ORIGINAL_PYTHON_VERSION}"
  echo "============================================="
} >> "${MAIN_LOG}"
