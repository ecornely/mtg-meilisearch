# Utilisation de mtgjson

Pour télécharger la dernière version de toutes les cartes:
https://mtgjson.com/downloads/all-files/

Pour télécharger la dernière version d'un set:
https://mtgjson.com/downloads/all-sets/

Pour voir tous les fichiers disponibles:
https://mtgjson.com/api/v5/

# Utilisation de AllPrintings et jq
Obtenir le fichier avec 
```shell
wget https://mtgjson.com/api/v5/AllPrintings.json.xz 
xz -d AllPrintings.json.xz 
```

Pour trouver une carte par son nom: 
`cat AllPrintings.json | jq '.data[] | .cards[] | select (.name=="Amrou Seekers")' | less -r`

Pour traduire toutes les cartes:
`./translate_all.sh`