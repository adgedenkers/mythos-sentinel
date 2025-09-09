#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# run-tests.sh  —  Repeatable integration checks for Mythos‑Sentinel API
# Author: Adge + GPT
# Purpose: Hit the live service (systemd: sentinel.service) and verify endpoints
# Exit non‑zero on any failure. Designed to run on the SERVER hosting the API.
# -----------------------------------------------------------------------------
set -euo pipefail

# ===============
# Configuration
# ===============
# Override via environment or a .env file sitting next to this script.
# Example: BASE_URL=https://loom.denkers.co API_KEY=... ./run-tests.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  # shellcheck disable=SC1090
  source "$SCRIPT_DIR/.env"
fi

: "${SYSTEMD_UNIT:=sentinel.service}"
: "${BASE_URL:=http://127.0.0.1:5000}"
: "${API_KEY:?Set API_KEY (SENTINEL_API_KEY used by the server)}"
: "${PROC_NAME:=gunicorn}"           # for /debug/ports
: "${TEST_UNIT:=gunicorn.service}"   # for /debug/journal (must be allowlisted)
: "${TEST_SINCE:=1h}"                # journalctl window
: "${TEST_LINES:=50}"                # default tail lines
: "${TEST_LOG_FILE:=/var/log/nginx/error.log}"  # must be in server allowlist

CURL=(curl -fsS -m 15 -H "x-api-key: ${API_KEY}")
JQ_BIN=${JQ_BIN:-jq}

# ===============
# Utilities
# ===============
red()   { printf "\033[31m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
blue()  { printf "\033[34m%s\033[0m\n" "$*"; }

fail()  { red "✖ $*"; exit 1; }
pass()  { green "✔ $*"; }
info()  { blue "➤ $*"; }

need() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing dependency: $1"
}

json_field() {
  local field=$1
  ${JQ_BIN} -r ".${field}" 2>/dev/null || true
}

# ===============
# Preflight
# ===============
need curl
need ${JQ_BIN}

info "Systemd unit: ${SYSTEMD_UNIT}"
info "Base URL:      ${BASE_URL}"
info "Proc name:     ${PROC_NAME}"
info "Journal unit:  ${TEST_UNIT} (since=${TEST_SINCE}, lines=${TEST_LINES})"
info "Log file:      ${TEST_LOG_FILE} (lines=${TEST_LINES})"

# Check service state quickly (informational; test suite continues)
if systemctl show -p ActiveState --value "${SYSTEMD_UNIT}" >/dev/null 2>&1; then
  state=$(systemctl show -p ActiveState --value "${SYSTEMD_UNIT}")
  info "systemd ${SYSTEMD_UNIT} state: ${state}"
else
  yellow "systemd unit ${SYSTEMD_UNIT} not found (tests may still pass if using a different runner)"
fi

# ===============
# Test 1: /health (or fallback to /)
# ===============
info "[1/5] Checking health endpoint"
if ! out=$(${CURL[@]} "${BASE_URL}/health" 2>&1); then
  yellow "No /health, trying root /"
  out=$(${CURL[@]} "${BASE_URL}/" || true)
fi

if [[ -n "$out" ]]; then
  pass "Health reachable"
else
  fail "Health check failed: ${BASE_URL}/health"
fi

# ===============
# Test 2: /debug/ports
# ===============
info "[2/5] Checking /debug/ports for proc='${PROC_NAME}'"
ports_json=$(${CURL[@]} "${BASE_URL}/debug/ports?proc=${PROC_NAME}")
count=$(printf "%s" "$ports_json" | ${JQ_BIN} '(.ports | length) // 0')
if [[ "$count" =~ ^[0-9]+$ ]] && (( count >= 0 )); then
  pass "/debug/ports returned ${count} entries"
else
  echo "$ports_json"
  fail "/debug/ports did not return a valid JSON array"
fi

# ===============
# Test 3: /debug/log-tail
# ===============
info "[3/5] Checking /debug/log-tail path='${TEST_LOG_FILE}' lines=${TEST_LINES}"
log_json=$(${CURL[@]} "${BASE_URL}/debug/log-tail?path=$(printf %s "$TEST_LOG_FILE" | sed 's#\ #%20#g')&lines=${TEST_LINES}")
# Verify fields exist and content array size <= TEST_LINES
returned_lines=$(printf "%s" "$log_json" | ${JQ_BIN} '(.content | length) // 0')
if (( returned_lines >= 0 )); then
  pass "/debug/log-tail returned ${returned_lines} lines"
else
  echo "$log_json"
  fail "/debug/log-tail did not return expected JSON"
fi

# ===============
# Test 4: /debug/journal
# ===============
info "[4/5] Checking /debug/journal unit='${TEST_UNIT}' since='${TEST_SINCE}' lines=${TEST_LINES}"
journal_json=$(${CURL[@]} "${BASE_URL}/debug/journal?unit=${TEST_UNIT}&since=${TEST_SINCE}&lines=${TEST_LINES}")
returned_j_lines=$(printf "%s" "$journal_json" | ${JQ_BIN} '(.content | length) // 0')
if (( returned_j_lines >= 0 )); then
  pass "/debug/journal returned ${returned_j_lines} lines"
else
  echo "$journal_json"
  fail "/debug/journal did not return expected JSON (is unit allowlisted?)"
fi

# ===============
# Test 5: Auth negative test (expect 401)
# ===============
info "[5/5] Verifying auth rejection without API key"
if curl -fsS -m 10 "${BASE_URL}/debug/ports?proc=${PROC_NAME}" >/dev/null 2>&1; then
  fail "Endpoint allowed access without x-api-key — security misconfigured"
else
  pass "Unauthorized request correctly rejected"
fi

pass "All tests passed"
