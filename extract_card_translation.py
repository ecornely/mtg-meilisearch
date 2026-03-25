import re
import sqlite3
import json

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
    

if __name__ == "__main__":
    extract_card_translations('/home/corne/tmp/Raw_CardDatabase_7cca6803f9ecd5ad3578065ba0f6487a.mtga', '/home/corne/tmp/transation.json')