"""Apply the reviewed taxonomy without rewriting any puzzle or changing its index."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))
def write(path, data):
    (ROOT / path).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

# Canonical worlds may share a playable collection until enough motifs exist.
LAYOUT = [
    ("beginning", "Das erste Licht", "spark", "ffd17c", 0, ["base"]),
    ("nature", "Tierwelt", "paw", "ffc17a", 1, ["animals", "birds", "ocean"]),
    ("plants", "Pflanzen & Garten", "flower", "85efa9", 7, ["flowers", "garden"]),
    ("landscapes", "Landschaften & Naturkräfte", "mountain", "b9a0ff", 8, ["landscapes", "lakes", "coasts", "deserts"]),
    ("celebrations", "Feste & Jahreszeiten", "snow", "ff9c83", 2, ["winter", "christmas", "halloween", "easter"]),
    ("home", "Zuhause & Alltag", "house", "ffbb93", 9, ["cozy"]),
    ("comfort", "Essen & Genuss", "cup", "ff90b7", 5, ["fruit", "bakery", "taste", "meals"]),
    ("craft", "Handwerk & Arbeitswelten", "tool", "f0da7f", 10, ["workshop"]),
    ("discovery", "Technik & Wissenschaft", "chip", "77dfe8", 3, ["computers", "smartphones", "technology", "communication", "science_basics"]),
    ("space", "Weltraum & Zukunft", "planet", "a997ff", 11, ["space", "spaceflight", "cosmos"]),
    ("travel", "Unterwegs & Bauwerke", "city", "73d9ff", 4, ["vehicles", "rail", "ships", "aircraft", "skylines", "world", "travel", "camping"]),
    ("imagination", "Kunst & Literatur", "palette", "ff95c9", 6, ["art"]),
    ("leisure", "Musik, Spiel & Sport", "music", "df9aff", 12, ["music", "ball_sports", "sports", "toys"]),
    ("fantasy", "Fantasie & Märchen", "moon", "dca1ff", 13, ["fantasy", "creatures"]),
]
GROUPS = {
    "base": ("Einstieg", "spark", "ffd17c"), "animals": ("Tiere an Land", "paw", "ffc17a"),
    "birds": ("Vögel", "bird", "79c9ff"), "ocean": ("Meerestiere & Riffe", "fish", "64e6e2"),
    "flowers": ("Blumen & Blüten", "flower", "ff87bd"), "garden": ("Garten & grünes Leben", "tree", "72f09e"),
    "landscapes": ("Berge & Naturkräfte", "mountain", "c6a2ff"), "lakes": ("Seen & Flüsse", "fish", "76dfff"),
    "coasts": ("Küsten & Inseln", "mountain", "70e6cc"), "deserts": ("Wüsten & Savannen", "mountain", "ffd18a"),
    "winter": ("Winter & Eis", "snow", "91e9ff"), "christmas": ("Weihnachten", "tree", "ff7b88"),
    "halloween": ("Halloween", "moon", "ffb066"), "easter": ("Ostern", "flower", "e4a0ff"),
    "cozy": ("Kleine Alltagsmomente", "house", "c2a6ff"), "fruit": ("Obst", "flower", "a4ee78"),
    "bakery": ("Gebäck & süße Freuden", "cup", "ffcb82"), "taste": ("Getränke & Café", "cup", "ff9bbd"),
    "meals": ("Kochen & Küche", "cup", "ffab74"), "workshop": ("Werkstatt & Handwerk", "tool", "f0da7f"),
    "computers": ("Computer & Bürotechnik", "chip", "7faaff"), "smartphones": ("Smartphones & Apps", "phone", "f99cdc"),
    "technology": ("Elektronik & Mechanik", "chip", "6af0d5"), "communication": ("Kommunikation & Aufnahme", "phone", "ffd078"),
    "science_basics": ("Physik & Chemie", "flask", "c6a2ff"), "space": ("Sonne, Mond & Planeten", "planet", "b99aff"),
    "spaceflight": ("Raumfahrt & Forschung", "planet", "79c9ff"), "cosmos": ("Zukunft & erfundene Welten", "city", "ffb973"),
    "vehicles": ("Straßenfahrzeuge", "car", "ffab74"), "rail": ("Schienenverkehr", "train", "f0da7f"),
    "ships": ("Schiffe & Boote", "ship", "64e6e2"), "aircraft": ("Fluggeräte", "plane", "b99aff"),
    "skylines": ("Städte & Skylines", "city", "a8a1ff"), "world": ("Wahrzeichen & Baukunst", "city", "7bdfff"),
    "travel": ("Reisen & Orientierung", "mountain", "82edb1"), "camping": ("Camping & Outdoor", "tree", "ffc17a"),
    "art": ("Kunst & Bücher", "palette", "ff95c9"), "music": ("Musik & Medien", "music", "b299ff"),
    "ball_sports": ("Ballsport", "ball", "ffab74"), "sports": ("Sport & Bewegung", "ball", "73e3ec"),
    "toys": ("Spielzeug & Kindheit", "spark", "ffd078"), "fantasy": ("Märchenwelten & Magie", "moon", "dca1ff"),
    "creatures": ("Fabelwesen", "paw", "ff9bbd"),
}

def group_for(a):
    w, c = a["world"], a["category"]
    rules = {
        "intro": {"Einstieg": "base"},
        "animals": {"Säugetiere": "animals", "Reptilien": "animals", "Vögel": "birds", "Meerestiere & Riffe": "ocean"},
        "plants": {"Blumen & Blüten": "flowers"},
        "nature": {"Seen & Flüsse": "lakes", "Küsten & Inseln": "coasts", "Wüsten & Savannen": "deserts"},
        "seasons": {"Winter & Eis": "winter", "Weihnachten": "christmas", "Halloween": "halloween", "Ostern": "easter"},
        "food": {"Obst": "fruit", "Brot & Gebäck": "bakery", "Süßigkeiten & Desserts": "bakery", "Getränke & Café": "taste"},
        "tech": {"Druck & Vervielfältigung": "computers", "Computer & Gaming": "computers", "Smartphones & Apps": "smartphones", "Kommunikation & Aufnahme": "communication"},
        "space": {"Sonnensystem & Himmelskörper": "space", "Raumfahrt & Erkundung": "spaceflight", "Raumstationen & Weltraumforschung": "spaceflight"},
        "travel": {"Straßenfahrzeuge": "vehicles", "Schienenverkehr": "rail", "Schiffe & Wasserfahrzeuge": "ships", "Fluggeräte": "aircraft", "Städte & Skylines": "skylines", "Wahrzeichen & Baukunst": "world", "Reisen & Orientierung": "travel", "Camping & Outdoor": "camping"},
        "leisure": {"Musik & Instrumente": "music", "Fotografie & Film": "music", "Ballsport": "ball_sports", "Spielzeug & Kindheit": "toys"},
        "fantasy": {"Fabelwesen": "creatures"},
    }
    defaults = {"plants": "garden", "nature": "landscapes", "home": "cozy", "food": "meals", "craft": "workshop", "tech": "technology", "science": "science_basics", "space": "cosmos", "culture": "art", "leisure": "sports", "fantasy": "fantasy"}
    return rules.get(w, {}).get(c, defaults.get(w))

def main():
    proposal = read("planning/ArrowWay-Katalog-Zuordnung-Vorschlag.json")
    catalog = read("collections/catalog.json")
    previous = read("collections/journey.json")
    old_worlds = previous.get("legacy_worlds", previous["worlds"])
    assignments = {a["path"]: dict(a, group=group_for(a)) for a in proposal["assignments"]}
    for a in assignments.values():
        # Use intact UTF-8 labels from the original puzzle, rather than an old
        # index which contained replacement characters in some German words.
        document = read(a["path"].removeprefix("res://"))
        if a["old_collection"] != "base":
            a["title"] = document["title"]
            a["old_collection_title"] = document["collection"]["title"]
            a["existing_tags"] = document.get("tags", [])
    assert len(assignments) == 509 and all(a["group"] in GROUPS for a in assignments.values())
    assert len(catalog["levels"]) == 500
    group_counts = {g: 0 for g in GROUPS}
    for a in assignments.values(): group_counts[a["group"]] += 1
    assert all(group_counts.values())
    worlds = []
    for wid, title, icon, color, ad_id, groups in LAYOUT:
        worlds.append(dict(id=wid, title=title, subtitle="Entdecke die Kunstwerke dieser Themenwelt", icon=icon, color=color, ad_id=ad_id, groups=groups))
    registry = {g: dict(id=g, title=v[0], icon=v[1], color=v[2], count=group_counts[g]) for g, v in GROUPS.items()}
    for w in proposal["worlds"]:
        for i, c in enumerate(w["categories"]):
            c["id"] = f'{w["id"]}_{i+1:02d}'
            c["status"] = "prepared" if c["existing_count"] == 0 else "populated"
            c["playable_groups"] = sorted({a["group"] for a in assignments.values() if a["world"] == w["id"] and a["category"] == c["title"]})
            for a in assignments.values():
                if a["world"] == w["id"] and a["category"] == c["title"]: a["category_id"] = c["id"]
    for entry in catalog["levels"]:
        a = assignments[entry["path"]]
        entry["title"] = a["title"]
        entry["tags"] = a["existing_tags"]
        entry.setdefault("legacy_collection", entry["collection"].copy())
        entry["collection"] = dict(id=a["group"], title=registry[a["group"]]["title"], order=entry["legacy_collection"]["order"])
        entry["taxonomy"] = dict(world=a["world"], category=a["category_id"])
    write("collections/catalog.json", catalog)
    write("collections/journey.json", dict(version=3, worlds=worlds, groups=registry, legacy_worlds=old_worlds))
    write("collections/taxonomy.json", dict(version=1, worlds=proposal["worlds"], assignments=list(assignments.values())))
    lines = ["# ArrowWay – aktueller Katalog", "", "509 Motive · 14 spielbare Themenwelten · 43 Sammlungen", "", "Vorbereitete, leere Kategorien erscheinen noch nicht im Spiel. Kleine befüllte Kategorien sind zunächst in größeren Sammlungen gebündelt.", ""]
    for w in worlds:
        lines += [f'## {w["title"]}', ""]
        lines += [f'- {registry[g]["title"]}: {group_counts[g]} Motive' for g in w["groups"]]
        lines += [""]
    lines += ["## Vollständige Planung", "", "17 übergeordnete Themen und 123 fachliche Unterkategorien sind in `collections/taxonomy.json` vorbereitet. Medizin und Geschichte erhalten erst mit eigenen Motiven sichtbare Stationen. Wissenschaft beginnt mit Physik und Chemie im Technikbereich.", "", "Motivdateien, Reihenfolge, Farben, Pfeile, Abschlusstexte und Favoritenpfade bleiben erhalten. Alte erreichbare Sammlungen behalten beim Upgrade Zugriff auf ihre neuen Zielgruppen; dieser Zugriff ist kein Abschluss-Häkchen.", ""]
    for w in proposal["worlds"]:
        lines += [f'### {w["title"]}', ""]
        for c in w["categories"]:
            state = "vorbereitet; Motive fehlen noch" if not c["existing_count"] else f'{c["existing_count"]} vorhandene Motive'
            lines += [f'- **{c["title"]}** — {state}']
        lines += [""]
    lines += ["## Pflege und Spielstand", "", "`tools/organize_catalog.py` setzt die geprüfte Zuordnung reproduzierbar um. Die ursprünglichen Sammlungen in den Leveldateien bleiben als Gestaltungsrezepte erhalten. Beim Neugenerieren wendet der Godot-Generator anschließend die aktuelle Taxonomie auf den Katalogindex an. Die Reihenfolge der Leveldateien darf beim Umbau nicht verändert werden.", "", "Gespeicherte Freischaltungen verwenden feste Sammlungs-IDs. Beim Upgrade werden zuvor erreichte Sammlungen auf ihre neuen Zielgruppen übertragen. Bei aufgeteilten Themenwelten erscheinen nur bereits erreichbare Zweige. Neue Spielstände folgen weiterhin der vollständigen Abschlussregel. Werbung verwendet feste Themenwelt-Schlüssel, damit ein Umbau vorhandene Zähler und Schutzphasen nicht verschiebt.", ""]
    (ROOT / "planning/KATALOGSTRUKTUR_AKTUELL.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"Assigned {len(assignments)} motifs to {len(worlds)} worlds / {len(registry)} groups")

if __name__ == "__main__": main()
