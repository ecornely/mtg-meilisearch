#!/bin/bash
source ~/.env.sh
curl \
  --silent \
  -X POST 'http://localhost:7700/indexes/dictionary/documents?primaryKey=id' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BEARER" \
  --data-binary @./translations.json
