#!/bin/bash
curl -s -X POST 'https://www.ecornely.be/mtg/search' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer fc6450378f49c9d5a0503cb2c048e28112692408591bec6f7505a451a4826223' \
  --data '{ "q": "Fractaliser", "limit": 10, "showRankingScore": true, "showRankingScoreDetails": true}'
