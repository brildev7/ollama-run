#!/bin/bash

# Script to manage the Ollama server

export OLLAMA_MODELS="/data/ollama/models"
export OLLAMA_MAX_LOADED_MODELS=4
export OLLAMA_NUM_PARALLEL=10
export OLLAMA_DEBUG=1
export OLLAMA_TMPDIR="/data/ollama/tmp"
export OLLAMA_KEEP_ALIVE=-1

LOG_FILE="/data/ollama/server.log"
PID_FILE="/data/ollama/ollama.pid"

# Allow overriding host and port via environment variables
export OLLAMA_HOST="0.0.0.0:15119"
OLLAMA_COMMAND="env CUDA_VISIBLE_DEVICES=0 ollama serve"

# Function to start the server
start() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null; then
            echo "Ollama server is already running with PID: $PID"
            exit 1
        else
            # The process is not running, but the PID file exists.
            # This can happen if the server was not stopped correctly.
            echo "Warning: PID file found but no process with PID $PID is running. Removing stale PID file."
            rm -f "$PID_FILE"
        fi
    fi

    # Check for foreground option
    if [ "$1" == "--foreground" ] || [ "$1" == "fg" ]; then
        echo "Starting Ollama server in the foreground..."
        # In foreground mode, we don't create a PID file because the script will be blocked.
        # The user can stop it with Ctrl+C.
        $OLLAMA_COMMAND
    else
        echo "Starting Ollama server in the background..."
        # Start the server in the background and redirect output
        nohup $OLLAMA_COMMAND > "$LOG_FILE" 2>&1 &
        # Get the PID of the last background process
        PID=$!
        # Save the PID to the PID file
        echo $PID > "$PID_FILE"
        echo "Ollama server started with PID: $PID. Log file: $LOG_FILE"
    fi
}

# Function to stop the server
stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Ollama server is not running (or PID file not found)."
        # Exit gracefully for restart command
        return 0
    fi

    PID=$(cat "$PID_FILE")
    if ! ps -p "$PID" > /dev/null; then
        echo "Ollama server is not running (process with PID $PID not found)."
        rm -f "$PID_FILE"
        # Exit gracefully for restart command
        return 0
    fi

    echo "Stopping Ollama server with PID: $PID..."
    # Send a termination signal
    kill "$PID"
    # Wait for the process to terminate
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null; then
            echo "Ollama server stopped."
            rm -f "$PID_FILE"
            return 0
        fi
        sleep 1
    done

    # If it's still running, force kill it
    echo "Ollama server did not stop gracefully. Forcing shutdown..."
    kill -9 "$PID"
    rm -f "$PID_FILE"
    echo "Ollama server stopped forcefully."
}

# Function to check the status of the server
status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null; then
            echo "Ollama server is running with PID: $PID"
        else
            echo "Ollama server is not running, but PID file exists. Removing stale PID file."
            rm -f "$PID_FILE"
        fi
    else
        echo "Ollama server is not running."
    fi
}

# Function to restart the server
restart() {
    echo "Restarting Ollama server..."
    stop
    # Add a small delay to ensure the port is freed
    sleep 2
    start
}

# Main script logic
case "$1" in
    start)
        start "$2"
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart} [--foreground|fg]"
        exit 1
        ;;
esac

exit 0
