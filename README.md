# Base de donnée de traduction en/fr pour MTG

## Donnée du jeux MTG Arena
Trouver le fichier de traduction avec `find /home/corne/.steam/steam/steamapps -name "*CardDatabase*.mtga"`
Utiliser le script extract_card_translation.py pour transformer le SQLite des traductions du jeux en un json

## Donnée MTGjson
Dans le dossier mtgjson télécharger AllPrintings sur le site de mtgjson et utiliser le script translate_all.sh pour avoir un json

## Fusion de plusieurs json
jq -c -s 'add | group_by(.en) | map(add)' mtgjson/translations.json mtga/translations.json > translations.json

# Mise en place du docker

## Environement

Créer un fichier .env avec :

```
MEILI_MASTER_KEY=<bearer>
```

## Charger les données:

### Configuration de l'index
```shell
curl \
  -X PATCH 'http://localhost:7700/indexes/dictionary/settings' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BEARER" \
  --data '{
  "searchableAttributes": [
    "en",
    "fr"
  ],
  "displayedAttributes": [
    "en",
    "fr"
  ],
  "rankingRules": [
    "words",
    "proximity",
    "exactness"
  ],
  "typoTolerance": {
    "enabled": false,
    "minWordSizeForTypos": {
      "oneTypo": 6,
      "twoTypos": 10
    },
    "disableOnAttributes": [],
    "disableOnWords": []
  },
  "pagination": {
    "maxTotalHits": 100
  }
}'
  ```
### Upload

```shell
curl \
  -X POST 'http://localhost:7700/indexes/dictionary/documents?primaryKey=id' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BEARER" \
  --data-binary @./translations.json
```

Suivi de la tache d'indexation avec :
```shell
curl 'http://localhost:7700/tasks/1' -H "Authorization: Bearer $BEARER"
```

## Utiliser la recherche

Pour utiliser la recherche, on peut le faire avec un bearer read-only plutôt que de prendre celui d'admin qui est dans le .env. Pour obtenir ce bearer, il faut interroger:

```shell
curl -s 'http://localhost:7700/keys' -H "Authorization: Bearer $BEARER" \
  | jq -C '.results[] | select (.actions[]|contains("search")) | select((.name | test("Chat API"))!=true)'
```

Ensuite avec l'un ou l'autre bearer on peut faire:

```shell
curl -s -X POST 'http://localhost:7700/indexes/dictionary/search' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer e076c0c6561ef0e04495fe0deb264a6db4f14a456db121e9b788aea35165ed8b' \
  --data '{ "q": "Dragn", "limit": 1 }'
```

Ce qui donne un json comme ceci:

```json
{
  "hits": [
    {
      "en": "Daredevil Dragster",
      "fr": "Dragster casse-cou"
    }
  ],
  "query": "Dragn",
  "processingTimeMs": 0,
  "limit": 1,
  "offset": 0,
  "estimatedTotalHits": 202,
  "requestUid": "019d25b5-97e9-7693-afad-8b65e5fac7ba"
}
```


