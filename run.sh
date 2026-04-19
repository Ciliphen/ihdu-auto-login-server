#!/bin/bash

set -e

# Resolve the script directory so cron can run it from any working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Store logs by day under the project directory, e.g. logs/2026-04-19.log.
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/$(date +%F).log"

# Ensure the log directory exists and remove logs older than 30 days.
mkdir -p "$LOG_DIR"
find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mtime +30 -delete

# Redirect all subsequent stdout/stderr to today's log file.
exec >> "$LOG_FILE" 2>&1

echo "[$(date '+%F %T')] Start network check"

# Check whether the network is already available.
# This rule is based on the campus network behavior you tested locally.
if curl -s -i baidu.com | grep -q 'baidu.com'; then
    echo "[$(date '+%F %T')] Network OK, skip login"
    exit 0
fi

# Run the campus network login script only when the check above fails.
/home/xilifeng/miniconda3/bin/python /home/xilifeng/ihdu-login/login.py

echo "[$(date '+%F %T')] Login finished"
echo "=================================================="
