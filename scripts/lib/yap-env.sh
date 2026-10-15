#!/usr/bin/env bash
# Load and save the yap API key outside the skill directory.
# File: ${XDG_CONFIG_HOME:-$HOME/.config}/yap/env
# Only YAP_API_URL, YAP_API_KEY, YAP_WEBHOOK_URL, and YAP_WEBHOOK_SECRET are read.
# An already-set environment variable wins over the file.

yap_config_file() {
  local base="${XDG_CONFIG_HOME:-}"
  if [[ -z "$base" ]]; then
    [[ -n "${HOME:-}" ]] || return 1
    base="${HOME}/.config"
  fi
  printf '%s/yap/env' "$base"
}

yap_load_config() {
  local file line key val
  file=$(yap_config_file) || return 0
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      ''|\#*) continue ;;
      YAP_API_URL=*|YAP_API_KEY=*|YAP_WEBHOOK_URL=*|YAP_WEBHOOK_SECRET=*)
        key=${line%%=*}
        val=${line#*=}
        if [[ "$val" == \"*\" && "$val" == *\" ]]; then
          val=${val#\"}
          val=${val%\"}
        fi
        if [[ -z "${!key:-}" ]]; then
          printf -v "$key" '%s' "$val"
          export "$key"
        fi
        ;;
    esac
  done <"$file"
}

# Returns 1 when the key is missing. The caller exits 0 so the person's task
# still runs; the message is how the agent learns the key is gone.
yap_prepare() {
  local file
  yap_load_config
  if [[ -z "${YAP_API_URL:-}" ]]; then
    YAP_API_URL="https://yap-api.desperate.dk"
    export YAP_API_URL
  fi
  if [[ -n "${YAP_API_KEY:-}" ]]; then
    return 0
  fi
  file=$(yap_config_file 2>/dev/null || true)
  echo "yap: API key missing. Not in the environment or ${file:-the persistent yap config}. Tell the person, run yap-setup, save the key there (mode 600), and pair the glass again." >&2
  return 1
}

# Rewrite the config file from the current environment. Keeps webhook fields.
yap_write_config() {
  local file dir tmp
  [[ -n "${YAP_API_KEY:-}" ]] || return 1
  file=$(yap_config_file) || return 1
  dir=$(dirname "$file")
  mkdir -p "$dir"
  chmod 700 "$dir" 2>/dev/null || true
  tmp=$(mktemp "${dir}/.env.XXXXXX")
  {
    printf 'YAP_API_URL=%s\n' "${YAP_API_URL:-https://yap-api.desperate.dk}"
    printf 'YAP_API_KEY=%s\n' "$YAP_API_KEY"
    if [[ -n "${YAP_WEBHOOK_URL:-}" ]]; then
      printf 'YAP_WEBHOOK_URL=%s\n' "$YAP_WEBHOOK_URL"
    fi
    if [[ -n "${YAP_WEBHOOK_SECRET:-}" ]]; then
      printf 'YAP_WEBHOOK_SECRET=%s\n' "$YAP_WEBHOOK_SECRET"
    fi
  } >"$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$file"
}
