#!/bin/bash

# Script to test PostgreSQL environment
# This script will clean up existing containers, kill processes using PostgreSQL port,
# and start a fresh PostgreSQL environment

set -e

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

POSTGRES_PORT=5432
POSTGRES_COMPOSE_FILE="postgres_docker-compose.yml"
POSTGRES_ENV_FILE="db_mktdata.env"
DATA_DIR="$HOME/Downloads/mktdata_storage"

is_port_free() {
    local port=$1
    if ! nc -z localhost "$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

check_postgres_status() {
    print_status "info" "Checking PostgreSQL status..."

    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet postgresql 2>/dev/null; then
            print_status "warning" "PostgreSQL system service is running"
            systemctl status postgresql --no-pager -l 2>/dev/null || true
        else
            print_status "info" "PostgreSQL system service is not running"
        fi
    fi

    local postgres_procs=$(ps aux | grep -E "(postgres|postmaster)" | grep -v grep || true)
    if [ -n "$postgres_procs" ]; then
        print_status "warning" "Found PostgreSQL processes:"
        echo "$postgres_procs"
    else
        print_status "info" "No PostgreSQL processes found"
    fi

    if ! is_port_free "$POSTGRES_PORT"; then
        print_status "warning" "Port $POSTGRES_PORT is in use:"
        if command -v lsof &> /dev/null; then
            sudo lsof -i:"$POSTGRES_PORT" 2>/dev/null || true
        fi
        if command -v netstat &> /dev/null; then
            sudo netstat -tlnp 2>/dev/null | grep ":$POSTGRES_PORT " || true
        fi
    else
        print_status "success" "Port $POSTGRES_PORT is free"
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

    # Check if processes are still running, use SIGKILL if needed
    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            print_status "warning" "Process $pid still running, force killing..."
            sudo kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    return 0
}

# Kill processes using netstat
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

# Kill processes using fuser
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

    # Try SIGTERM first
    if sudo fuser -TERM "$port/tcp" &>/dev/null; then
        print_status "info" "Sent SIGTERM to processes using fuser"
        sleep 3

        # Check if still in use, then force kill
        if sudo fuser "$port/tcp" &>/dev/null; then
            print_status "warning" "Processes still running, force killing..."
            sudo fuser -KILL "$port/tcp" &>/dev/null || true
        fi
        return 0
    else
        print_status "warning" "Failed to kill processes with fuser SIGTERM"
        # Try force kill directly
        if sudo fuser -k "$port/tcp" &>/dev/null; then
            print_status "info" "Force killed processes using fuser"
            return 0
        else
            print_status "warning" "Failed to kill processes with fuser"
            return 1
        fi
    fi
}

# Kill processes using ss
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

# Kill processes using pkill
kill_with_pkill() {
    local port=$1
    print_status "config" "Method 5: Trying pkill..."

    if ! command -v pkill &> /dev/null; then
        print_status "warning" "pkill command not found"
        return 1
    fi

    # Try to kill postgres processes
    local postgres_pids=$(pgrep -f "postgres.*$port" 2>/dev/null || pgrep -f "postgres" 2>/dev/null || true)

    if [ -z "$postgres_pids" ]; then
        print_status "warning" "No postgres processes found with pkill"
        return 1
    fi

    print_status "info" "Found postgres processes: $postgres_pids"

    # Try SIGTERM first
    sudo pkill -TERM -f "postgres" 2>/dev/null || true
    sleep 3

    # Check if still running, then force kill
    if pgrep -f "postgres" &>/dev/null; then
        print_status "warning" "Postgres processes still running, force killing..."
        sudo pkill -KILL -f "postgres" 2>/dev/null || true
    fi

    return 0
}

# Main function to kill PostgreSQL processes on port
kill_postgres_port() {
    local port=$1
    local max_attempts=3
    local attempt=1

    print_status "info" "Checking port $port..."

    if is_port_free "$port"; then
        print_status "success" "Port $port is already free!"
        return 0
    fi

    print_status "warning" "Port $port is in use, attempting to free it..."

    # First, try to stop PostgreSQL service if it's running
    if command -v systemctl &> /dev/null && systemctl is-active --quiet postgresql 2>/dev/null; then
        print_status "info" "Stopping PostgreSQL system service..."
        sudo systemctl stop postgresql
        sleep 3

        if is_port_free "$port"; then
            print_status "success" "Port $port freed by stopping PostgreSQL service!"
            return 0
        fi
    fi

    # If service stop didn't work, try killing individual processes
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

        # Check if port is now free
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

    # Final check with detailed error reporting
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

# Clean up Docker resources
cleanup_docker() {
    print_status "info" "Cleaning up Docker resources..."

    print_status "config" "Stopping PostgreSQL containers..."
    docker compose -f "$POSTGRES_COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true

    print_status "config" "Pruning Docker system..."
    docker system prune --volumes --force 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
    docker builder prune -a --force 2>/dev/null || true
    docker image prune -a --force 2>/dev/null || true

    print_status "success" "Docker cleanup completed"
}

# Clean up data directory
cleanup_data() {
    print_status "info" "Cleaning up data directory..."

    if [ -d "$DATA_DIR" ]; then
        print_status "config" "Removing data directory: $DATA_DIR"
        rm -rf "$DATA_DIR"
        print_status "success" "Data directory removed"
    else
        print_status "info" "Data directory does not exist, skipping"
    fi
}

start_postgres() {
    print_status "info" "Starting PostgreSQL environment..."

    if [ ! -f "$POSTGRES_ENV_FILE" ]; then
        print_status "warning" "Environment file $POSTGRES_ENV_FILE not found"
        print_status "info" "Creating default environment file..."

        cat > "$POSTGRES_ENV_FILE" << EOF
# PostgreSQL Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_DB=mktdata

# PgAdmin Configuration
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin123

# Other settings
POSTGRES_PORT=5432
EOF
        print_status "success" "Created default environment file: $POSTGRES_ENV_FILE"
        print_status "warning" "Please review and update the credentials in $POSTGRES_ENV_FILE"
    fi

    if [ ! -f "$POSTGRES_COMPOSE_FILE" ]; then
        print_status "error" "Docker Compose file $POSTGRES_COMPOSE_FILE not found"
        exit 1
    fi

    export DOCKER_BUILDKIT=1

    print_status "config" "Starting PostgreSQL containers..."
    if ! docker compose --env-file "$POSTGRES_ENV_FILE" -f "$POSTGRES_COMPOSE_FILE" up -d; then
        print_status "error" "Failed to start PostgreSQL containers"
        exit 1
    fi

    print_status "config" "Waiting for PostgreSQL to be ready..."
    sleep 10

    print_status "config" "Showing PostgreSQL logs..."
    docker compose --env-file "$POSTGRES_ENV_FILE" -f "$POSTGRES_COMPOSE_FILE" logs db_mktdata || true

    print_status "config" "Testing PostgreSQL connection..."
    local max_wait=30
    local wait_time=0

    while [ $wait_time -lt $max_wait ]; do
        if docker compose --env-file "$POSTGRES_ENV_FILE" -f "$POSTGRES_COMPOSE_FILE" exec -T db_mktdata pg_isready -U postgres &>/dev/null; then
            print_status "success" "PostgreSQL is ready and accepting connections!"
            return 0
        fi

        sleep 2
        wait_time=$((wait_time + 2))
        print_status "info" "Waiting for PostgreSQL... ($wait_time/${max_wait}s)"
    done

    print_status "warning" "PostgreSQL may not be fully ready yet, but containers are running"
}

# Initialize Docker environment
init_docker() {
    print_status "config" "Checking Docker environment..."

    if [ -f "cli/docker_init.sh" ]; then
        bash cli/docker_init.sh
    else
        print_status "warning" "docker_init.sh not found in cli/ directory"
        print_status "info" "Performing basic Docker checks..."

        if ! command -v docker &> /dev/null; then
            print_status "error" "Docker is not installed or not in PATH"
            exit 1
        fi

        if ! docker info &>/dev/null; then
            print_status "error" "Docker daemon is not running or not accessible"
            print_status "info" "Try: sudo systemctl start docker"
            exit 1
        fi

        print_status "success" "Docker is accessible"

        # Test Docker with hello-world
        print_status "debug" "Testing Docker connection with hello-world..."
        if docker run --rm hello-world &>/dev/null; then
            print_status "success" "Docker connection test passed"
        else
            print_status "error" "Docker connection test failed"
            exit 1
        fi

        print_status "success" "Docker is ready"
    fi
}

# Main function
main() {
    print_status "info" "Starting PostgreSQL environment test..."

    # Change to project root directory
    cd "$PROJECT_ROOT"

    # Show current status first
    check_postgres_status

    # Initialize Docker
    init_docker

    # Clean up existing Docker resources
    cleanup_docker

    # Clean up data directory
    cleanup_data

    # Kill processes using PostgreSQL port
    print_status "config" "Checking and freeing PostgreSQL port..."
    if ! kill_postgres_port "$POSTGRES_PORT"; then
        print_status "error" "Failed to free PostgreSQL port $POSTGRES_PORT"
        print_status "info" "You may need to manually resolve the port conflict"
        print_status "info" "Consider using a different port or stopping system PostgreSQL service"
        exit 1
    fi

    # Start PostgreSQL environment
    start_postgres

    print_status "success" "PostgreSQL environment test completed successfully!"
    print_status "info" "PostgreSQL should now be available on port $POSTGRES_PORT"
    print_status "info" "Use 'docker compose logs -f' to monitor the containers"
}

# Handle script interruption
trap 'print_status "warning" "Script interrupted"; exit 130' INT TERM

# Run main function with all arguments
main "$@"
