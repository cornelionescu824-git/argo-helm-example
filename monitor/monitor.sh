#!/bin/sh
# Sidecar: monitors a configurable URL at a configurable interval
# Env: MONITOR_URL, MONITOR_INTERVAL (seconds)

URL="${MONITOR_URL:-https://www.google.com}"
INTERVAL="${MONITOR_INTERVAL:-10}"

echo "Monitoring $URL every ${INTERVAL}s"
while true; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$URL" 2>/dev/null || echo "000")
  echo "$(date '+%Y-%m-%dT%H:%M:%S') - $URL -> HTTP $STATUS"
  sleep "$INTERVAL"
done
