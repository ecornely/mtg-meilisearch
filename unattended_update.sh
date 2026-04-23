#!/usr/bin/env zsh

echo "Downloading AllPrintings.json.xz from mtgjson.com..."
wget https://mtgjson.com/api/v5/AllPrintings.json.xz -O mtgjson/AllPrintings.json.xz
echo "Decompressing AllPrintings.json.xz..."
xz -d mtgjson/AllPrintings.json.xz
echo "MTG json translation..."
bash mtgjson/translate_all.sh

if jq -e 'type == "array" and length >= 20000' mtgjson/translations.json > /dev/null; then
    echo "MTG arena translation..."
    python3 mtga/extract_card_translation.py
    if jq -e 'type == "array" and length >= 10000' mtgjson/translations.json > /dev/null; then
        echo "Joining translations..."
        jq -c -s 'add | group_by(.en) | map(add)' mtgjson/translations.json mtga/translations.json > translations.json
        if jq -e 'type == "array" and length >= 30000' mtgjson/translations.json > /dev/null; then
            echo "Translations joined successfully."
            scp translations.json vps:
            scp update_translation.sh vps:
            ssh vps "~/update_translation.sh"
        else
            echo "Could not join translations"
        fi
    else
        echo "Could not translate from MTG arena"
    fi
else
    echo "Could not translate AllPrintings.json"
fi

