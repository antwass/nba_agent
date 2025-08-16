import json
import re
import unicodedata

def normalize_name(name):
    """
    Nettoie un nom de joueur pour une meilleure correspondance :
    - Met en minuscules
    - Supprime les accents et caractères spéciaux
    - Supprime les suffixes (Jr., III, etc.)
    """
    # Supprime les suffixes comme Jr., Sr., II, III, IV
    name = re.sub(r'\s+(jr|sr|ii|iii|iv)\.?$', '', name.lower().strip())
    # Normalise les caractères (enlève les accents, etc.)
    # Ex: "Nikola Jokić" -> "nikola jokic"
    normalized = unicodedata.normalize('NFD', name).encode('ascii', 'ignore').decode('utf-8')
    return normalized

def merge_databases_smarter():
    """
    Fusionne les données en normalisant les noms pour une meilleure correspondance.
    """
    try:
        with open('nba_players_updated.json', 'r', encoding='utf-8') as f:
            master_players = json.load(f)

        with open('nba_overall_potential.json', 'r', encoding='utf-8') as f:
            new_stats = json.load(f)

        print("Fichiers chargés avec succès.")

        # --- ÉTAPE 2: Créer un dictionnaire de stats avec des noms normalisés ---
        stats_map = {
            normalize_name(player['nom']): {
                'Overall': player.get('Overall'),
                'potential': player.get('potential')
            } 
            for player in new_stats
        }
        print(f"{len(stats_map)} joueurs avec des stats uniques chargés et normalisés.")

        # --- ÉTAPE 3: Parcourir et mettre à jour en utilisant les noms normalisés ---
        updated_count = 0
        not_found_players = []

        for player in master_players:
            full_name = f"{player['prenom']} {player['nom']}"
            normalized_full_name = normalize_name(full_name)

            if normalized_full_name in stats_map:
                new_player_stats = stats_map[normalized_full_name]
                
                player['overall'] = new_player_stats['Overall']
                player['potential'] = new_player_stats['potential']
                
                updated_count += 1
            else:
                not_found_players.append(full_name)

        print(f"\n{updated_count} joueurs ont été mis à jour.")

        if not_found_players:
            print(f"\n{len(not_found_players)} joueurs n'ont toujours pas été trouvés :")
            # Pour ne pas surcharger, on n'affiche que les 10 premiers
            print(", ".join(not_found_players[:10]) + ('...' if len(not_found_players) > 10 else ''))

        # --- ÉTAPE 4: Sauvegarder la base de données finale ---
        with open('nba_database_complete_v2.json', 'w', encoding='utf-8') as f:
            json.dump(master_players, f, indent=2, ensure_ascii=False)

        print("\n✅ Fusion améliorée terminée ! Fichier prêt dans 'nba_database_complete_v2.json'.")

    except FileNotFoundError as e:
        print(f"❌ ERREUR : Fichier manquant : '{e.filename}'")
    except Exception as e:
        print(f"❌ Une erreur inattendue est survenue : {e}")

# Lancer la fusion améliorée
merge_databases_smarter()