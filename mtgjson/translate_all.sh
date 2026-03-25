#!/usr/bin/env bash

FILE="AllPrintings.json"

if [[ ! -f "$FILE" ]]; then
    echo "Erreur : $FILE introuvable." >&2
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
' > translations.json