#!/usr/bin/env bash
set -euo pipefail

# Default values by type
DEFAULT_BOOLEAN=true
DEFAULT_SIDE="left"
DEFAULT_NUMERIC=0
DEFAULT_ROLE="color7"
DEFAULT_PALETTE="#FFFFFF"

# Specific per-key overrides
declare -A OVERRIDES=(
  [".ui.time.show"]="false"
  [".ui.time.side"]="right"
  [".ui.dir.max_ratio"]="40"

  [".theme.roles.hostname"]="color2"
  [".theme.roles.git"]="color3"
  [".theme.roles.dir"]="color4"
  [".theme.roles.time"]="color5"
  [".theme.roles.arrow"]="color6"
  [".theme.roles.success"]="color2"
  [".theme.roles.error"]="color1"
  [".theme.roles.warning"]="color3"
  [".theme.roles.text"]="color7"
)

BOOLEAN_KEYS=()
SIDE_KEYS=()
NUMERIC_KEYS=()
ROLE_KEYS=()
PALETTE_KEYS=()

usage() {
  cat <<'EOF'
Usage:
  generate_state_json.sh \
    --boolean .ui.git.show .ui.hostname.show ... \
    --side .ui.hostname.side .ui.time.side ... \
    --numeric .ui.dir.max_ratio ... \
    --role .theme.roles.git ... \
    --palette .palette.color0 .palette.color1 ...

Optional:
  --output /path/to/file.json

Notes:
  - Keys must use jq-style dotted paths, e.g. .ui.git.show
  - Default values are assigned by bucket/type
  - Some keys may have hardcoded overrides inside the script
EOF
}

OUTPUT=""

current_bucket=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --boolean)
      current_bucket="boolean"
      shift
      ;;
    --side)
      current_bucket="side"
      shift
      ;;
    --numeric)
      current_bucket="numeric"
      shift
      ;;
    --role)
      current_bucket="role"
      shift
      ;;
    --palette)
      current_bucket="palette"
      shift
      ;;
    --output)
      [[ $# -ge 2 ]] || { echo "Missing argument for --output" >&2; exit 1; }
      OUTPUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
    *)
      [[ -n "$current_bucket" ]] || {
        echo "Key '$1' appeared before any bucket flag" >&2
        exit 1
      }

      case "$current_bucket" in
        boolean) BOOLEAN_KEYS+=("$1") ;;
        side)    SIDE_KEYS+=("$1") ;;
        numeric) NUMERIC_KEYS+=("$1") ;;
        role)    ROLE_KEYS+=("$1") ;;
        palette) PALETTE_KEYS+=("$1") ;;
        *)
          echo "Internal parser error: unknown bucket '$current_bucket'" >&2
          exit 1
          ;;
      esac
      shift
      ;;
  esac
done

# Builds a jq expression:
# setpath(["ui","git","show"]; true)
build_setpath_expr() {
  local key="$1"
  local value="$2"
  local trimmed
  local IFS='.'
  local parts=()
  local jq_path=""
  local first=1
  local part

  trimmed="${key#.}"
  read -r -a parts <<< "$trimmed"

  jq_path="["
  for part in "${parts[@]}"; do
    if [[ $first -eq 0 ]]; then
      jq_path+=","
    fi
    jq_path+="\"$part\""
    first=0
  done
  jq_path+="]"

  printf 'setpath(%s; %s)' "$jq_path" "$value"
}

jq_expr='{}'

append_key() {
  local key="$1"
  local type="$2"
  local value
  local expr

  if [[ -v OVERRIDES["$key"] ]]; then
    value="${OVERRIDES[$key]}"
  else
    case "$type" in
      boolean) value="$DEFAULT_BOOLEAN" ;;
      side)    value="\"$DEFAULT_SIDE\"" ;;
      numeric) value="$DEFAULT_NUMERIC" ;;
      role)    value="\"$DEFAULT_ROLE\"" ;;
      palette) value="\"$DEFAULT_PALETTE\"" ;;
      *)
        echo "Unknown type '$type' for key '$key'" >&2
        exit 1
        ;;
    esac
  fi

  # Normalize override values into valid jq literals
  case "$type" in
    boolean|numeric)
      ;;
    side|role|palette)
      [[ "$value" =~ ^\".*\"$ ]] || value="\"$value\""
      ;;
  esac

  expr="$(build_setpath_expr "$key" "$value")"
  jq_expr+=" | $expr"
}

for key in "${BOOLEAN_KEYS[@]}"; do append_key "$key" "boolean"; done
for key in "${SIDE_KEYS[@]}";    do append_key "$key" "side";    done
for key in "${NUMERIC_KEYS[@]}"; do append_key "$key" "numeric"; done
for key in "${ROLE_KEYS[@]}";    do append_key "$key" "role";    done
for key in "${PALETTE_KEYS[@]}"; do append_key "$key" "palette"; done

if [[ -n "$OUTPUT" ]]; then
  jq -n "$jq_expr" > "$OUTPUT"
else
  jq -n "$jq_expr"
fi
