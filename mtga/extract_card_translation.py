#!/bin/env python3

import os
import re
import sqlite3
import json

from pathlib import Path

def generate_pk(text):
    if not text:
        return ""
    slug = text.lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    slug = slug.strip("-")
    return slug

def extract_card_translations(sqlite_db_path, output_json_path):
    conn = sqlite3.connect(sqlite_db_path)
    cursor = conn.cursor()

    query = """
SELECT
    c.TitleId as id,
    (SELECT Loc FROM Localizations_enUS en WHERE en.LocId = c.TitleId ORDER BY Formatted ASC LIMIT 1) as en,
    (SELECT Loc FROM Localizations_frFR fr WHERE fr.LocId = c.TitleId ORDER BY Formatted ASC LIMIT 1) as fr
FROM
    Cards c
WHERE
    c.IsPrimaryCard = 1
ORDER BY c.TitleId;
    """

    cursor.execute(query)
    with open(output_json_path, 'w', encoding='utf-8') as f:
        f.write('[\n')
        for row in cursor:
            json.dump({"id": generate_pk(row[1]), "en": row[1], "fr": row[2]}, f, ensure_ascii=False, indent=None)
            f.write(',\n')
        f.seek(f.tell() - 2)
        f.write('\n]\n')

    conn.close()


def find_mtga_card_database():
    base_path = Path.home() / ".steam/steam/steamapps"
    
    if not base_path.exists():
        raise FileNotFoundError(f"Le dossier Steam est introuvable : {base_path}")

    try:
        return next(base_path.rglob("*CardDatabase*.mtga"))
    except StopIteration:
        raise FileNotFoundError("Raw_CardDatabase .mtga file not found in Player.log.")


def copy_card_database(src_path, dest_path):
    import shutil
    shutil.copy(src_path, dest_path)

def get_script_path():
    import os
    return os.path.dirname(os.path.realpath(__file__))

if __name__ == "__main__":
    #copy_card_database(find_mtga_card_database(), 'card_database.db')
    extract_card_translations('card_database.db', os.path.join(get_script_path(), 'translations.json'))