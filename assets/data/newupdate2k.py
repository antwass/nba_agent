import json
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup

# --- Configuration de Selenium ---
chrome_options = Options()
# Une fenêtre Chrome va s'ouvrir.
chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36")

try:
    driver = webdriver.Chrome(options=chrome_options)
    print("Une fenêtre Chrome va s'ouvrir. Veuillez ne pas la fermer, le script la pilote.")
except Exception as e:
    print(f"ERREUR : Impossible de démarrer chromedriver : {e}")
    exit()

final_player_data = []

try:
    # --- La liste complète des 30 équipes ---
    team_urls = [
        "https://www.2kratings.com/teams/atlanta-hawks", "https://www.2kratings.com/teams/boston-celtics",
        "https://www.2kratings.com/teams/brooklyn-nets", "https://www.2kratings.com/teams/charlotte-hornets",
        "https://www.2kratings.com/teams/chicago-bulls", "https://www.2kratings.com/teams/cleveland-cavaliers",
        "https://www.2kratings.com/teams/dallas-mavericks", "https://www.2kratings.com/teams/denver-nuggets",
        "https://www.2kratings.com/teams/detroit-pistons", "https://www.2kratings.com/teams/golden-state-warriors",
        "https://www.2kratings.com/teams/houston-rockets", "https://www.2kratings.com/teams/indiana-pacers",
        "https://www.2kratings.com/teams/la-clippers", "https://www.2kratings.com/teams/los-angeles-lakers",
        "https://www.2kratings.com/teams/memphis-grizzlies", "https://www.2kratings.com/teams/miami-heat",
        "https://www.2kratings.com/teams/milwaukee-bucks", "https://www.2kratings.com/teams/minnesota-timberwolves",
        "https://www.2kratings.com/teams/new-orleans-pelicans", "https://www.2kratings.com/teams/new-york-knicks",
        "https://www.2kratings.com/teams/oklahoma-city-thunder", "https://www.2kratings.com/teams/orlando-magic",
        "https://www.2kratings.com/teams/philadelphia-76ers", "https://www.2kratings.com/teams/phoenix-suns",
        "https://www.2kratings.com/teams/portland-trail-blazers", "https://www.2kratings.com/teams/sacramento-kings",
        "https://www.2kratings.com/teams/san-antonio-spurs", "https://www.2kratings.com/teams/toronto-raptors",
        "https://www.2kratings.com/teams/utah-jazz", "https://www.2kratings.com/teams/washington-wizards"
    ]
    
    # --- ÉTAPE 1: Lister tous les joueurs ---
    player_links = set()
    for team_url in team_urls:
        print(f"Analyse de l'équipe : {team_url}")
        driver.get(team_url)
        time.sleep(1)
        team_soup = BeautifulSoup(driver.page_source, 'html.parser')
        player_rows = team_soup.find('tbody').find_all('tr')
        for row in player_rows:
            link_tag = row.find('a')
            if link_tag and 'href' in link_tag.attrs:
                player_links.add(link_tag['href'])
    print(f"\n{len(player_links)} joueurs uniques trouvés. Début du scraping des stats...")

    # --- ÉTAPE 2: Visiter chaque page et extraire les stats voulues ---
    for player_url in list(player_links):
        driver.get(player_url)
        print(f"Scraping de : {player_url}")
        
        # On fait défiler pour charger les éléments
        driver.execute_script("window.scrollTo(0, 500);")
        time.sleep(1)

        player_soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        player_name = player_soup.find('h1').text.strip()
        overall_rating = None
        potential_rating = None

        # Recherche de la note "Overall"
        overall_tag = player_soup.find('span', class_='attribute-box-player')
        if overall_tag:
            try:
                overall_rating = int(overall_tag.text.strip())
            except ValueError:
                print(f"  -> Avertissement: Impossible de lire l'Overall pour {player_name}")

        # Recherche de la note "Potential"
        stat_cards = player_soup.find_all('div', class_='card-header')
        for card in stat_cards:
            h4 = card.find('h4', class_='card-title')
            if h4 and 'Potential' in h4.text:
                value_span = h4.find('span', class_=lambda c: c and c.startswith('attribute-box'))
                if value_span:
                    try:
                        potential_rating = int(value_span.text.strip())
                        break # On a trouvé le potentiel, on arrête de chercher
                    except ValueError:
                        print(f"  -> Avertissement: Impossible de lire le Potentiel pour {player_name}")

        # On crée l'objet JSON avec la structure demandée
        player_data = {
            "nom": player_name,
            "Overall": overall_rating,
            "potential": potential_rating
        }
        final_player_data.append(player_data)
        
    # --- ÉTAPE 3: Sauvegarde finale ---
    with open('nba_overall_potential.json', 'w', encoding='utf-8') as f:
        json.dump(final_player_data, f, indent=4, ensure_ascii=False) # indent=4 pour une meilleure lisibilité
        
    print(f"\n✅ Mission accomplie ! {len(final_player_data)} joueurs ont été sauvegardés dans 'nba_overall_potential.json'.")

except Exception as e:
    print(f"\n❌ Une erreur est survenue : {e}")

finally:
    print("Fermeture du navigateur.")
    driver.quit()