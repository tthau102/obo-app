#!/bin/bash
#
# Script: health-check.sh
# Description: Check application health status
# Usage: ./scripts/monitoring/health-check.sh [URL]
#

set -e

URL="${1:-http://localhost:8080}"

echo "========================================="
echo "Health Check"
echo "========================================="
echo "Target: $URL"
echo ""

# Check main health endpoint
echo "--- Main Health Status ---"
HTTP_CODE=$(curl -s -o /tmp/health.json -w '%{http_code}' "$URL/actuator/health" || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Status: UP (HTTP $HTTP_CODE)"
    cat /tmp/health.json | python3 -m json.tool 2>/dev/null || cat /tmp/health.json
else
    echo "❌ Status: DOWN (HTTP $HTTP_CODE)"
    [ -f /tmp/health.json ] && cat /tmp/health.json
    exit 1
fi

echo ""

# Check liveness probe
echo "--- Liveness Probe ---"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$URL/actuator/health/liveness" || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Liveness: UP (HTTP $HTTP_CODE)"
else
    echo "❌ Liveness: DOWN (HTTP $HTTP_CODE)"
fi

# Check readiness probe
echo "--- Readiness Probe ---"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$URL/actuator/health/readiness" || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Readiness: UP (HTTP $HTTP_CODE)"
else
    echo "❌ Readiness: DOWN (HTTP $HTTP_CODE)"
fi

echo ""

# Check info endpoint
echo "--- Application Info ---"
HTTP_CODE=$(curl -s -o /tmp/info.json -w '%{http_code}' "$URL/actuator/info" || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    cat /tmp/info.json | python3 -m json.tool 2>/dev/null || cat /tmp/info.json
else
    echo "Info endpoint not available (HTTP $HTTP_CODE)"
fi

# Cleanup
rm -f /tmp/health.json /tmp/info.json

echo ""
echo "Health check completed"
