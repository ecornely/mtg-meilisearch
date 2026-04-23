#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="$SCRIPT_DIR/AllPrintings.json"
OUTPUT="$SCRIPT_DIR/translations.json"

if [[ ! -f "$FILE" ]]; then
    echo "Erreur : $FILE introuvable dans $SCRIPT_DIR" >&2
    exit 1
fi

cat "$FILE" | jq -r -c '
  [
    .data[] 
    | .cards[] 
    | select(
        .name != null and
        (.foreignData | length) > 1 and 
        any(.foreignData[]; .language == "French")
      )
    | { 
        "id": (.name | ascii_downcase | gsub("[^a-z0-9]+"; "-") | gsub("^-|-$"; "")), 
        "en": .name, 
        "fr": (.foreignData[] | select(.language == "French") | .name) 
      }
  ] | unique_by(.en) | sort_by(.en)
' > "$OUTPUT"