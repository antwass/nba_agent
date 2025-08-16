import os, json, time, random, argparse
import requests

API_KEY = os.environ.get("BALLDONTLIE_API_KEY") or "REPLACE_ME"  # mets ta clé ici si tu veux
BASE_URL = "https://api.balldontlie.io/v1"

TEAMS_URL   = f"{BASE_URL}/teams"
PLAYERS_URL = f"{BASE_URL}/players"

def http_get(url, headers, params, backoff_state: dict):
    """GET avec gestion 429 (Retry-After ou backoff progressif)."""
    while True:
        r = requests.get(url, headers=headers, params=params, timeout=45)
        if r.status_code == 429:
            ra = r.headers.get("Retry-After")
            wait = int(ra) if ra and ra.isdigit() else (30 + backoff_state["k"] * 15)
            wait += random.randint(0, 5)
            backoff_state["k"] += 1
            print(f"[429] Too many requests. Attente {wait}s puis reprise {url} …")
            time.sleep(wait)
            continue
        backoff_state["k"] = 0
        if r.status_code >= 400:
            try:
                print("API error payload:", r.json())
            except Exception:
                print("API error text:", r.text)
            r.raise_for_status()
        return r.json()

def load_current_team_ids(headers) -> set[int]:
    """
    Récupère toutes les équipes puis conserve seulement celles
    dont 'conference' est 'East' ou 'West' (les franchises actuelles).
    """
    backoff = {"k": 0}
    teams: list[dict] = []
    # TEAMS n'est pas paginé (petite liste), on fait un seul appel
    payload = http_get(TEAMS_URL, headers, {}, backoff)
    for t in payload.get("data", payload if isinstance(payload, list) else []):
        conf = (t.get("conference") or "").strip()
        if conf in ("East", "West"):
            teams.append(t)
    ids = {int(t["id"]) for t in teams}
    print(f"Équipes actuelles détectées: {len(ids)} (ids: {sorted(list(ids))})")
    return ids

def map_pos(s: str | None) -> str:
    if not s:
        return "SG"
    s = s.upper()
    if "C" in s: return "C"
    if "F" in s: return "SF"
    if "G" in s: return "PG"
    return "SG"

def clean_player(p: dict) -> dict:
    team = p.get("team") or {}
    return {
        "extId": str(p.get("id")),
        "first_name": p.get("first_name") or "",
        "last_name":  p.get("last_name")  or "",
        "position":   map_pos(p.get("position")),
        "age": None,  # pas fourni par /players
        "team": {
            "id":           team.get("id"),
            "full_name":    team.get("full_name"),
            "abbreviation": team.get("abbreviation"),
            "conference":   team.get("conference"),
        },
    }

def fetch_active_players(per_page=100, start_page=1, cap=650, save_path="../assets/data/nba_players_active_2025.json"):
    if not API_KEY or API_KEY == "REPLACE_ME":
        raise RuntimeError("Renseigne ta clé: variable d'env BALLEDONTLIE_API_KEY ou remplace API_KEY dans le script.")

    headers = {"Authorization": API_KEY}  # IMPORTANT: pas de 'Bearer'
    os.makedirs(os.path.dirname(save_path), exist_ok=True)

    # 1) IDs des équipes actuelles
    current_team_ids = load_current_team_ids(headers)

    # 2) Parcours des pages /players et filtre par équipes actuelles
    out: list[dict] = []
    page = start_page
    backoff = {"k": 0}

    while True:
        params = {"per_page": per_page, "page": page}
        payload = http_get(PLAYERS_URL, headers, params, backoff)
        data = payload.get("data", [])
        if not data:
            print("Fin de pagination (data vide).")
            break

        # filtre: joueurs dont l'équipe fait partie des franchises actuelles
        batch = []
        for p in data:
            team = p.get("team") or {}
            tid = team.get("id")
            # garde uniquement les joueurs rattachés à une équipe actuelle
            if isinstance(tid, int) and tid in current_team_ids:
                batch.append(clean_player(p))

        out.extend(batch)
        print(f"page {page}: +{len(batch)} actifs (total={len(out)})")

        # sauvegarde incrémentale
        with open(save_path, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=2)

        page += 1
        if len(out) >= cap:
            print(f"Cap atteint ({cap}). Arrêt anticipé.")
            break

        time.sleep(0.5)  # limiter le débit

    print(f"✅ Écrit {len(out)} joueurs actifs -> {save_path}")
    return out

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", type=int, default=1, help="Page de départ (pour reprise)")
    ap.add_argument("--per-page", type=int, default=100, help="Taille de page (max 100)")
    ap.add_argument("--cap", type=int, default=650, help="Limite avant arrêt anticipé")
    ap.add_argument("--out", type=str, default="../assets/data/nba_players_active_2025.json", help="Chemin du JSON de sortie")
    args = ap.parse_args()

    fetch_active_players(per_page=args.per_page, start_page=args.start, cap=args.cap, save_path=args.out)
