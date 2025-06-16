#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Default ports if none provided
DEFAULT_PORTS=(5432)

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

show_help() {
    echo "Usage: $0 [OPTIONS] [PORT1 PORT2 ...]"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo "  -v, --verbose   Enable verbose output"
    echo
    echo "Examples:"
    echo "  $0 5432                # Kill processes on port 5432"
    echo "  $0 5432 5433           # Kill processes on ports 5432 and 5433"
    echo "  $0 \"5432 5433\"        # Same as above (quoted)"
    echo "  $0 5432,5433           # Same as above (comma-separated)"
    echo "  $0                     # Use default port 5432"
    exit 0
}

parse_ports() {
    local ports=()

    # If no arguments provided, use defaults
    if [ $# -eq 0 ]; then
        ports=("${DEFAULT_PORTS[@]}")
        echo "${ports[@]}"
        return
    fi

    # Handle help flag
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                show_help
                ;;
        esac
    done

    # Process all arguments
    for arg in "$@"; do
        # Remove any commas and split by space
        local cleaned_arg=$(echo "$arg" | tr ',' ' ')
        for port in $cleaned_arg; do
            # Validate it's a number
            if [[ "$port" =~ ^[0-9]+$ ]]; then
                if (( port >= 1 && port <= 65535 )); then
                    ports+=("$port")
                else
                    print_status "error" "Port $port is not valid (must be 1-65535)"
                    exit 1
                fi
            else
                print_status "error" "'$port' is not a valid port number"
                exit 1
            fi
        done
    done

    # Remove duplicates
    local unique_ports=($(printf "%s\n" "${ports[@]}" | sort -u | tr '\n' ' '))
    echo "${unique_ports[@]}"
}

is_port_free() {
    local port=$1
    if ! nc -z localhost "$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

kill_with_lsof() {
    local port=$1
    print_status "config" "Method 1: Trying lsof..."

    if ! command -v lsof &> /dev/null; then
        print_status "warning" "lsof command not found, skipping to next method"
        return 1
    fi

    local pids=$(sudo lsof -t -i:"$port" 2>/dev/null || true)

    if [ -z "$pids" ]; then
        print_status "warning" "No processes found using port $port with lsof"
        return 1
    fi

    print_status "info" "Found processes with PIDs: $pids"

    print_status "debug" "Process details:"
    sudo lsof -i:"$port" 2>/dev/null || true

    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            print_status "info" "Sending SIGTERM to process $pid..."
            sudo kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    sleep 3

    # check if processes are still running, use SIGKILL if needed
    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            print_status "warning" "Process $pid still running, force killing..."
            sudo kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    return 0
}

kill_with_netstat() {
    local port=$1
    print_status "config" "Method 2: Trying netstat..."

    if ! command -v netstat &> /dev/null; then
        print_status "warning" "netstat command not found, skipping to next method"
        return 1
    fi

    local process_info=$(sudo netstat -tlnp 2>/dev/null | grep ":$port " || true)

    if [ -z "$process_info" ]; then
        print_status "warning" "No processes found using port $port with netstat"
        return 1
    fi

    print_status "info" "Found process info: $process_info"

    local pids=$(echo "$process_info" | awk '{print $7}' | cut -d'/' -f1 | grep -E '^[0-9]+$' | sort -u || true)

    if [ -z "$pids" ]; then
        print_status "warning" "Could not extract PID from netstat output"
        return 1
    fi

    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            print_status "info" "Sending SIGTERM to process $pid..."
            sudo kill -TERM "$pid" 2>/dev/null || true
            sleep 2

            if kill -0 "$pid" 2>/dev/null; then
                print_status "warning" "Process $pid still running, force killing..."
                sudo kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
    done

    return 0
}

kill_with_fuser() {
    local port=$1
    print_status "config" "Method 3: Trying fuser..."

    if ! command -v fuser &> /dev/null; then
        print_status "warning" "fuser command not found, skipping to next method"
        return 1
    fi

    if ! sudo fuser "$port/tcp" &>/dev/null; then
        print_status "warning" "No processes found using port $port with fuser"
        return 1
    fi

    print_status "info" "Found processes using port $port, attempting to kill..."

    # try SIGTERM first
    if sudo fuser -TERM "$port/tcp" &>/dev/null; then
        print_status "info" "Sent SIGTERM to processes using fuser"
        sleep 3

        # check if still in use, then force kill
        if sudo fuser "$port/tcp" &>/dev/null; then
            print_status "warning" "Processes still running, force killing..."
            sudo fuser -KILL "$port/tcp" &>/dev/null || true
        fi
        return 0
    else
        print_status "warning" "Failed to kill processes with fuser SIGTERM"
        # try force kill directly
        if sudo fuser -k "$port/tcp" &>/dev/null; then
            print_status "info" "Force killed processes using fuser"
            return 0
        else
            print_status "warning" "Failed to kill processes with fuser"
            return 1
        fi
    fi
}

kill_with_ss() {
    local port=$1
    print_status "config" "Method 4: Trying ss..."

    if ! command -v ss &> /dev/null; then
        print_status "warning" "ss command not found, skipping to next method"
        return 1
    fi

    local process_info=$(sudo ss -tlnp 2>/dev/null | grep ":$port " || true)

    if [ -z "$process_info" ]; then
        print_status "warning" "No processes found using port $port with ss"
        return 1
    fi

    print_status "info" "Found process info: $process_info"

    local pids=$(echo "$process_info" | grep -oP 'pid=\K[0-9]+' | sort -u || true)

    if [ -z "$pids" ]; then
        print_status "warning" "Could not extract PID from ss output"
        return 1
    fi

    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            print_status "info" "Sending SIGTERM to process $pid..."
            sudo kill -TERM "$pid" 2>/dev/null || true
            sleep 2

            if kill -0 "$pid" 2>/dev/null; then
                print_status "warning" "Process $pid still running, force killing..."
                sudo kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
    done

    return 0
}

kill_with_pkill() {
    local port=$1
    print_status "config" "Method 5: Trying pkill..."

    if ! command -v pkill &> /dev/null; then
        print_status "warning" "pkill command not found"
        return 1
    fi

    # try to kill postgres processes
    local postgres_pids=$(pgrep -f "postgres.*$port" 2>/dev/null || pgrep -f "postgres" 2>/dev/null || true)

    if [ -z "$postgres_pids" ]; then
        print_status "warning" "No postgres processes found with pkill"
        return 1
    fi

    print_status "info" "Found postgres processes: $postgres_pids"

    # try SIGTERM first
    sudo pkill -TERM -f "postgres" 2>/dev/null || true
    sleep 3

    # check if still running, then force kill
    if pgrep -f "postgres" &>/dev/null; then
        print_status "warning" "Postgres processes still running, force killing..."
        sudo pkill -KILL -f "postgres" 2>/dev/null || true
    fi

    return 0
}

kill_port() {
    local port=$1
    local max_attempts=3
    local attempt=1

    print_status "info" "Checking port $port..."

    if is_port_free "$port"; then
        print_status "success" "Port $port is already free!"
        return 0
    fi

    print_status "warning" "Port $port is in use, attempting to free it..."

    if command -v systemctl &> /dev/null && systemctl is-active --quiet postgresql 2>/dev/null; then
        print_status "info" "Stopping PostgreSQL system service..."
        sudo systemctl stop postgresql
        sleep 3

        if is_port_free "$port"; then
            print_status "success" "Port $port freed by stopping PostgreSQL service!"
            return 0
        fi
    fi

    while [ $attempt -le $max_attempts ]; do
        print_status "info" "Attempt $attempt of $max_attempts to kill processes..."

        local methods=("kill_with_lsof" "kill_with_netstat" "kill_with_fuser" "kill_with_ss" "kill_with_pkill")
        local success=false

        for method in "${methods[@]}"; do
            if $method "$port"; then
                success=true
                sleep 2
                break
            fi
        done

        if is_port_free "$port"; then
            print_status "success" "Port $port is now free!"
            return 0
        fi

        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            print_status "warning" "Port still in use, waiting before retry..."
            sleep 5
        fi
    done

    if ! is_port_free "$port"; then
        print_status "error" "Failed to free port $port after $max_attempts attempts"
        print_status "info" "Current processes using port $port:"

        if command -v lsof &> /dev/null; then
            sudo lsof -i:"$port" 2>/dev/null || true
        fi
        if command -v netstat &> /dev/null; then
            sudo netstat -tlnp 2>/dev/null | grep ":$port " || true
        fi

        print_status "info" "Manual steps to resolve:"
        echo "  1. sudo systemctl stop postgresql"
        echo "  2. sudo pkill -f postgres"
        echo "  3. sudo kill -9 \$(sudo lsof -t -i:$port)"
        echo "  4. Reboot if necessary"
        echo "  5. Or use a different port in your docker-compose file"

        return 1
    fi

    return 0
}

main() {
    # Parse ports from arguments
    local ports=($(parse_ports "$@"))

    if [ ${#ports[@]} -eq 0 ]; then
        print_status "error" "No valid ports specified"
        exit 1
    fi

    print_status "info" "Processing ports: ${ports[*]}"

    local all_success=true
    for port in "${ports[@]}"; do
        print_status "config" "Checking and freeing port $port..."
        if ! kill_port "$port"; then
            all_success=false
        fi
    done

    if ! $all_success; then
        print_status "error" "Failed to free one or more ports"
        print_status "info" "You may need to manually resolve the port conflicts"
        exit 1
    fi

    print_status "success" "All specified ports processed successfully"
}

trap 'print_status "warning" "Script interrupted"; exit 130' INT TERM

main "$@"
