#!/usr/bin/env zsh

# --- Configuration & Paths ---
# {0:A:h} is a zsh-specific modifier: 
# A = Absolute path, h = Head (dirname)
SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

# Colors for terminal output
info() { echo "\033[1;34m[INFO]\033[0m $1" }
error() { echo "\033[1;31m[ERROR]\033[0m $1" >&2 }

# --- Help Function ---
usage() {
    cat << EOF
Usage: $(basename $0) [OPTIONS]

Options:
  -j, --json      Download and translate data from MTGJSON
  -a, --arena     Extract translations from MTG Arena files
  -n, --join      Merge JSON files (MTGJSON + Arena)
  -u, --upload    Upload files to the VPS
  --update        Execute the update script on the VPS via SSH
  
Groups:
  --all           Run ALL steps (default behavior if no args)
  --local         Run -j, -a, and -n only
  -h, --help      Display this help message

Example:
  $(basename $0) --local
  $(basename $0) -u --update
EOF
    exit 0
}

# --- Argument Parsing with zparseopts ---
zmodload zsh/zutil
zparseopts -D -E -A opts \
    j -json \
    a -arena \
    n -join \
    u -upload \
    -update \
    -all \
    -local \
    h -help

# Display help if requested
if (( ${+opts[-h]} || ${+opts[--help]} )); then
    usage
fi

# Logic for grouped options (Shortcuts)
# If no arguments are passed OR --all is present
if [[ $# -eq 0 && ${#opts} -eq 0 ]] || (( ${+opts[--all]} )); then
    opts[-j]="" opts[-a]="" opts[-n]="" opts[-u]="" opts[--update]=""
fi

if (( ${+opts[--local]} )); then
    opts[-j]="" opts[-a]="" opts[-n]=""
fi

# --- Processing Steps ---

# 1. MTG JSON
if (( ${+opts[-j]} || ${+opts[--json]} )); then
    info "Step: MTGJSON"
    mkdir -p mtgjson
    info "Downloading AllPrintings.json.xz..."
    wget -q --show-progress https://mtgjson.com/api/v5/AllPrintings.json.xz -O mtgjson/AllPrintings.json.xz
    
    info "Decompressing..."
    xz -df mtgjson/AllPrintings.json.xz 
    
    info "Running MTG json translation script..."
    bash mtgjson/translate_all.sh
    
    # Validation check
    if ! jq -e 'type == "array" and length >= 20000' mtgjson/translations.json >/dev/null; then
        error "MTGJSON translation failed or returned insufficient data."
        exit 1
    fi
fi

# 2. MTG ARENA
if (( ${+opts[-a]} || ${+opts[--arena]} )); then
    info "Step: MTG Arena Extraction"
    python3 mtga/extract_card_translation.py
    
    # Validation check
    if ! jq -e 'type == "array" and length >= 10000' mtga/translations.json >/dev/null; then
        error "MTG Arena extraction failed or returned insufficient data."
        exit 1
    fi
fi

# 3. JOIN
if (( ${+opts[-n]} || ${+opts[--join]} )); then
    info "Step: Joining translations"
    if [[ -f mtgjson/translations.json && -f mtga/translations.json ]]; then
        jq -c -s 'add | group_by(.en) | map(add)' mtgjson/translations.json mtga/translations.json > translations.json
        
        # Validation check for the merged file
        if ! jq -e 'type == "array" and length >= 30000' translations.json >/dev/null; then
            error "Joining failed: The resulting file does not meet size requirements."
            exit 1
        fi
        info "Translations joined successfully."
    else
        error "Missing source files for join. Did you run the -j and -a steps?"
        exit 1
    fi
fi

# 4. UPLOAD
if (( ${+opts[-u]} || ${+opts[--upload]} )); then
    info "Step: Uploading to VPS"
    if [[ -f translations.json ]]; then
        scp translations.json update_translation.sh vps:
    else
        error "translations.json not found. Please run the join step first."
        exit 1
    fi
fi

# 5. UPDATE (SSH)
if (( ${+opts[--update]} )); then
    info "Step: Triggering remote update via SSH"
    ssh vps "~/update_translation.sh"
fi

info "Workflow completed."