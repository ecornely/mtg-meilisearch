#!/usr/bin/env bash

FILE="AllPrintings.json"

if [[ ! -f "$FILE" ]]; then
    echo "Erreur : $FILE introuvable." >&2
    exit 1
fi

ENGLISH_NAME="Amrou Seekers"

cat "$FILE" | jq -r --arg name "$ENGLISH_NAME" '
  [
    .data[] 
    | .cards[] 
    | select(
        .name == $name and 
        (.foreignData | length) > 1 and 
        any(.foreignData[]; .language == "French")
      )
    | { "id": .identifiers.mcmId, "en": .name, "fr": (.foreignData[] | select(.language == "French")).name }
  ] | sort_by(.id) | reverse | first
'