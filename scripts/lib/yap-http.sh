#!/usr/bin/env bash
# Shared poster for the yap scripts.
# Timeouts, network errors, and 5xx retry in the background (1s, 2s, 4s, …).
# 4xx is not retried. A newer call in the same slot replaces an older body
# that is still retrying. Quiet calls return without waiting on the network.
#
# Sourced by the scripts. Also invoked as:
#   yap-http.sh retry <slot_dir> <api_origin> <connect_timeout> <max_time> <initial_sleep> <backoff_max>
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  if [[ "${1:-}" != "retry" ]]; then
    exit 0
  fi
  slot_dir="$2"
  api_origin="$3"
  connect_timeout="$4"
  max_time="$5"
  sleep_s="$6"
  backoff_max="$7"

  echo "$$" >"${slot_dir}/pid"
  while true; do
    if [[ "$sleep_s" != "0" ]]; then
      sleep "$sleep_s" || exit 0
    fi
    [[ -f "${slot_dir}/gen" ]] || exit 0
    gen=$(cat "${slot_dir}/gen" 2>/dev/null || echo "")
    method=$(cat "${slot_dir}/method" 2>/dev/null || echo "")
    path=$(cat "${slot_dir}/path" 2>/dev/null || echo "")
    key=$(cat "${slot_dir}/key" 2>/dev/null || echo "")
    [[ -n "$method" && -n "$path" && -n "$key" ]] || exit 0

    tmp=$(mktemp)
    curl_args=(
      --silent
      --connect-timeout "$connect_timeout"
      --max-time "$max_time"
      -o "$tmp"
      -w "%{http_code}"
      -X "$method"
      "${api_origin}${path}"
      -H "authorization: Bearer ${key}"
      -H "content-type: application/json"
    )
    if [[ "$method" != "GET" && "$method" != "DELETE" ]]; then
      curl_args+=(--data-binary @"${slot_dir}/body")
    fi
    code=$(curl "${curl_args[@]}" 2>/dev/null || true)
    [[ -n "$code" ]] || code="000"
    now_gen=$(cat "${slot_dir}/gen" 2>/dev/null || echo "")
    if [[ "$now_gen" != "$gen" ]]; then
      rm -f "$tmp"
      sleep_s=0
      continue
    fi
    if [[ "$code" =~ ^2 ]]; then
      cp "$tmp" "${slot_dir}/response" 2>/dev/null || true
      rm -f "$tmp" "${slot_dir}/pid"
      exit 0
    fi
    rm -f "$tmp"
    if [[ "$code" =~ ^4 ]]; then
      rm -f "${slot_dir}/pid"
      exit 0
    fi
    if [[ "$sleep_s" == "0" ]]; then
      sleep_s=1
    elif (( sleep_s < backoff_max )); then
      sleep_s=$((sleep_s * 2))
    fi
  done
fi

yap_http_connect_timeout() {
  printf '%s' "${YAP_HTTP_CONNECT_TIMEOUT:-5}"
}

yap_http_max_time() {
  printf '%s' "${YAP_HTTP_MAX_TIME:-10}"
}

yap_http_backoff_max() {
  printf '%s' "${YAP_HTTP_BACKOFF_MAX:-32}"
}

yap_http_kill_tree() {
  local pid="$1"
  [[ -n "$pid" ]] || return 0
  local child
  while read -r child; do
    [[ -n "$child" ]] || continue
    yap_http_kill_tree "$child"
  done < <(pgrep -P "$pid" 2>/dev/null || true)
  kill "$pid" 2>/dev/null || true
}

yap_http_dir() {
  local id dir
  id=$(
    node -e '
      const crypto = require("crypto");
      const h = crypto.createHash("sha256")
        .update((process.argv[1] || "") + "\0" + (process.argv[2] || ""))
        .digest("hex")
        .slice(0, 16);
      process.stdout.write(h);
    ' "$YAP_API_URL" "$YAP_API_KEY"
  )
  dir="${TMPDIR:-/tmp}/yap-retry-${id}"
  mkdir -p "$dir"
  chmod 700 "$dir" 2>/dev/null || true
  printf '%s' "$dir"
}

yap_http_stop_slot() {
  local slot_dir="$1"
  local old=""
  if [[ -f "${slot_dir}/pid" ]]; then
    old=$(cat "${slot_dir}/pid" 2>/dev/null || true)
  fi
  yap_http_kill_tree "$old"
  rm -f "${slot_dir}/pid"
}

yap_http_start_worker() {
  local slot_dir="$1"
  local api_origin="$2"
  local initial_sleep="$3"
  local lib pid
  lib="${BASH_SOURCE[0]}"
  nohup bash "$lib" retry "$slot_dir" "$api_origin" \
    "$(yap_http_connect_timeout)" "$(yap_http_max_time)" \
    "$initial_sleep" "$(yap_http_backoff_max)" \
    >/dev/null 2>&1 &
  pid="$!"
  printf '%s' "$pid" >"${slot_dir}/pid"
  disown "$pid" 2>/dev/null || true
}

# yap_http_call quiet|print|once METHOD /path [json_body] slot
# quiet: do not wait. The attempt and any retries run in the background.
# print: one foreground attempt. On 2xx or 4xx, print the body. On timeout,
#        network error, or 5xx, retry in the background and print nothing.
# once: one foreground attempt, print the body, do not retry. Sets YAP_HTTP_CODE.
yap_http_call() {
  local mode="$1"
  local method="$2"
  local path="$3"
  local body="${4:-}"
  local slot="$5"
  local api_origin="${YAP_API_URL%/}"
  local root slot_dir gen tmp code

  root=$(yap_http_dir)
  slot_dir="${root}/${slot}"
  mkdir -p "$slot_dir"
  chmod 700 "$slot_dir" 2>/dev/null || true

  yap_http_stop_slot "$slot_dir"

  gen=1
  if [[ -f "${slot_dir}/gen" ]]; then
    gen=$(cat "${slot_dir}/gen" 2>/dev/null || echo 0)
    [[ "$gen" =~ ^[0-9]+$ ]] || gen=0
    gen=$((gen + 1))
  fi
  printf '%s' "$method" >"${slot_dir}/method"
  printf '%s' "$path" >"${slot_dir}/path"
  printf '%s' "$body" >"${slot_dir}/body"
  printf '%s' "$YAP_API_KEY" >"${slot_dir}/key"
  chmod 600 "${slot_dir}/key" "${slot_dir}/body" 2>/dev/null || true
  printf '%s' "$gen" >"${slot_dir}/gen"
  rm -f "${slot_dir}/response"

  if [[ "$mode" == "quiet" ]]; then
    yap_http_start_worker "$slot_dir" "$api_origin" 0
    return 0
  fi

  tmp=$(mktemp)
  local curl_args=(
    --silent
    --show-error
    --connect-timeout "$(yap_http_connect_timeout)"
    --max-time "$(yap_http_max_time)"
    -o "$tmp"
    -w "%{http_code}"
    -X "$method"
    "${api_origin}${path}"
    -H "authorization: Bearer ${YAP_API_KEY}"
    -H "content-type: application/json"
  )
  if [[ "$method" != "GET" && "$method" != "DELETE" ]]; then
    curl_args+=(--data-binary @"${slot_dir}/body")
  fi
  code=$(curl "${curl_args[@]}" 2>/dev/null || true)
  [[ -n "$code" ]] || code="000"
  YAP_HTTP_CODE="$code"
  printf '%s' "$code" >"${slot_dir}/code"

  if [[ "$mode" == "once" ]]; then
    if [[ -s "$tmp" ]]; then
      cat "$tmp"
      echo
    fi
    rm -f "$tmp"
    return 0
  fi

  if [[ "$code" =~ ^2 || "$code" =~ ^4 ]]; then
    if [[ -s "$tmp" ]]; then
      cat "$tmp"
      echo
    fi
    rm -f "$tmp"
    return 0
  fi
  rm -f "$tmp"
  yap_http_start_worker "$slot_dir" "$api_origin" 1
  return 0
}
