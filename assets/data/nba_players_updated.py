import json

def update_player_ratings():
    """
    Met à jour les notes 'overall' des joueurs d'un fichier principal
    en utilisant un fichier de référence pour les notes.
    """
    try:
        # --- ÉTAPE 1: Charger les deux fichiers JSON ---
        with open('nba_2k_ratings_ALL_PAGES.json', 'r', encoding='utf-8') as f:
            scraped_data = json.load(f) # Fichier avec les bonnes notes

        with open('nba_players_with_age.json', 'r', encoding='utf-8') as f:
            main_players_data = json.load(f) # Votre fichier à mettre à jour

        print("Fichiers chargés avec succès.")

        # --- ÉTAPE 2: Créer un dictionnaire de notes pour une recherche rapide ---
        # Cela évite les doublons et rend la recherche quasi instantanée.
        # La clé est le nom du joueur, la valeur est sa note.
        ratings_map = {player['nom']: player['note_generale'] for player in scraped_data}
        print(f"{len(ratings_map)} notes uniques ont été extraites.")

        # --- ÉTAPE 3: Parcourir votre fichier principal et mettre à jour les notes ---
        updated_count = 0
        not_found_players = []

        for player in main_players_data:
            # On construit le nom complet à partir des champs "prenom" et "nom"
            # Note : Certains noms peuvent avoir des orthographes différentes (ex: Dončić vs Doncic)
            # Cette version simple fonctionnera pour la majorité des cas.
            full_name = f"{player['prenom']} {player['nom']}"

            # On cherche le nom complet dans notre dictionnaire de notes
            if full_name in ratings_map:
                new_rating = ratings_map[full_name]
                old_rating = player['overall']
                
                # On met à jour la note
                player['overall'] = new_rating
                updated_count += 1
                print(f"Mise à jour : {full_name} (Ancienne note : {old_rating}, Nouvelle note : {new_rating})")
            else:
                not_found_players.append(full_name)

        print(f"\n{updated_count} joueurs ont été mis à jour.")

        # Afficher les joueurs qui n'ont pas été trouvés
        if not_found_players:
            print("\nLes joueurs suivants n'ont pas été trouvés dans le fichier de notes (vérifiez l'orthographe) :")
            for name in not_found_players:
                print(f"- {name}")

        # --- ÉTAPE 4: Sauvegarder le résultat dans un nouveau fichier ---
        with open('nba_players_updated.json', 'w', encoding='utf-8') as f:
            json.dump(main_players_data, f, indent=2, ensure_ascii=False)

        print("\n✅ Opération terminée ! Le fichier 'nba_players_updated.json' a été créé avec toutes les données à jour.")

    except FileNotFoundError as e:
        print(f"❌ ERREUR : Un fichier est manquant. Assurez-vous que '{e.filename}' est dans le même dossier que le script.")
    except Exception as e:
        print(f"❌ Une erreur inattendue est survenue : {e}")

# Lancer la fonction de mise à jour
update_player_ratings()