import requests
import json
import time
from bs4 import BeautifulSoup

# URL de la page principale
main_url = 'https://eu.hoopshype.com/nba-2k/players/'
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

all_players_data = []

try:
    # --- ÉTAPE 1 : Récupérer les données de la Page 1 ET le Build ID ---
    print("Récupération de la page 1 et du Build ID...")
    response = requests.get(main_url, headers=headers)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, 'html.parser')

    data_script = soup.find('script', {'id': '__NEXT_DATA__'})
    json_data = json.loads(data_script.string)

    # On extrait le Build ID, nécessaire pour appeler l'API
    build_id = json_data['buildId']
    print(f"Build ID trouvé : {build_id}")

    # On extrait les joueurs de la première page en utilisant le chemin complet
    initial_players = json_data['props']['pageProps']['dehydratedState']['queries'][3]['state']['data']['pages'][0]['videoGameRatings']['videoGameRatings']
    for player in initial_players:
        full_name = f"{player['fullPlayer']['firstName']} {player['fullPlayer']['lastName']}"
        all_players_data.append({"nom": full_name, "note_generale": int(player['rating'])})
    
    print(f"{len(all_players_data)} joueurs de la page 1 ajoutés.")

    # --- ÉTAPE 2 : Boucler sur les pages 2 à 24 en appelant l'API ---
    for page_num in range(2, 25):
        
        # On construit l'URL de l'API pour les pages suivantes
        api_url = f"https://eu.hoopshype.com/_next/data/{build_id}/nba-2k/players.json?page={page_num}"
        
        print(f"Récupération de la page {page_num} via l'API...")
        response = requests.get(api_url, headers=headers)
        
        if response.status_code == 404:
            print(f"Page {page_num} non trouvée. Fin du scraping.")
            break
            
        response.raise_for_status()
        
        page_data = response.json()
        
        # --- CORRECTION FINALE ---
        # On utilise le MÊME chemin complet pour les données de l'API que pour la page 1
        players_list = page_data['pageProps']['dehydratedState']['queries'][3]['state']['data']['pages'][0]['videoGameRatings']['videoGameRatings']

        if not players_list:
            print(f"Aucun joueur sur la page {page_num}. Fin.")
            break

        for player in players_list:
            # On utilise aussi la MÊME méthode pour extraire le nom
            full_name = f"{player['fullPlayer']['firstName']} {player['fullPlayer']['lastName']}"
            all_players_data.append({"nom": full_name, "note_generale": int(player['rating'])})

        print(f"{len(players_list)} joueurs de la page {page_num} ajoutés.")
        time.sleep(1)

    # --- ÉTAPE 3 : Sauvegarde finale ---
    with open('nba_2k_ratings_ALL_PAGES.json', 'w', encoding='utf-8') as json_file:
        json.dump(all_players_data, json_file, indent=4, ensure_ascii=False)

    print(f"\n✅ Mission accomplie ! {len(all_players_data)} joueurs au total ont été sauvegardés dans 'nba_2k_ratings_ALL_PAGES.json'.")

except Exception as e:
    print(f"\n❌ Une erreur est survenue : {e}")