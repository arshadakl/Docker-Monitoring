set -euo pipefail

SLACK_WEBHOOK_URL="SLACK_WEBHOOK_URL"
LOG_FILE="/var/log/docker-monitor.log"


mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send Slack notification
send_slack_notification() {
    local message="$1"
    if ! curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\": \"$message\"}" "$SLACK_WEBHOOK_URL" >>"$LOG_FILE" 2>&1; then
        log_message "Error: Failed to send Slack notification"
    fi
}


cleanup() {
    log_message "Docker monitor service stopping..."
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT


declare -A processed_containers

log_message "Docker monitor service starting..."

send_slack_notification "🟢 *Docker Monitor Service:* Starting up on host $(hostname)"

while true; do
    if ! docker info >/dev/null 2>&1; then
        log_message "Waiting for Docker daemon to be ready..."
        sleep 10
        continue
    fi

    docker events --filter 'type=container' --filter 'event=die' | while IFS= read -r line; do
        log_message "Debug: Raw event line: $line"

        CONTAINER_ID=$(echo "$line" | awk '{print $4}')

        CONTAINER_ID=${CONTAINER_ID//[()]/}

        if [[ ${processed_containers[$CONTAINER_ID]} ]]; then
            log_message "Debug: Skipping duplicate event for container $CONTAINER_ID"
            continue
        fi

        processed_containers[$CONTAINER_ID]="1"

        CONTAINER_NAME=$(echo "$line" | grep -o 'name=[^,)]*' | cut -d= -f2)
        EXIT_CODE=$(echo "$line" | grep -o 'exitCode=[^,)]*' | cut -d= -f2)

        log_message "Debug: Extracted container ID: $CONTAINER_ID"
        log_message "Debug: Extracted container name: $CONTAINER_NAME"
        log_message "Debug: Exit code: $EXIT_CODE"

        # Validate container ID format
        if [[ ! $CONTAINER_ID =~ ^[a-f0-9]{12,64}$ ]]; then
            log_message "Debug: Invalid container ID format: $CONTAINER_ID"
            continue
        fi

        if [ -z "$CONTAINER_NAME" ]; then
            CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER_ID" 2>/dev/null | sed 's/^\///')
        fi

        CONTAINER_NAME=${CONTAINER_NAME:-Unknown}

        if [ "$EXIT_CODE" != "0" ]; then
            IMAGE=$(echo "$line" | grep -o 'image=[^,)]*' | cut -d= -f2)
            EXEC_DURATION=$(echo "$line" | grep -o 'execDuration=[^,)]*' | cut -d= -f2)

            MESSAGE="🚨 *Alert:* Docker container crash detected
            • Host: \`$(hostname)\`
            • Name: \`$CONTAINER_NAME\`
            • ID: \`$CONTAINER_ID\`
            • Image: $IMAGE
            • Exit Code: $EXIT_CODE
            • Execution Duration: ${EXEC_DURATION}s"

            send_slack_notification "$MESSAGE"
        else
            log_message "Debug: Container exited normally with exit code 0"
        fi

        if [ ${#processed_containers[@]} -gt 100 ]; then
            unset processed_containers
            declare -A processed_containers
        fi
    done

    log_message "Docker events stream ended. Restarting in 10 seconds..."
    sleep 10
done
