# 🏨 Agent de Classification des Leads Touristiques
## 🎉 Version 100% GRATUITE - Sans clé API !

Agent open-source pour collecter, scorer et classer les établissements touristiques en France (hôtels, gîtes, chambres d'hôtes).

## ✨ Sources de Données GRATUITES

- ✅ **OpenStreetMap** - Données ouvertes mondiales
- ✅ **Booking.com** - Scraping respectueux
- ✅ **Nominatim** - Géocodage gratuit
- ✅ Pas besoin de carte bancaire ni de clé API !

## 🚀 Installation Rapide

### 1. Installer les dépendances
```bash
pip install -r requirements.txt
```

### 2. Configurer l'environnement
```bash
cp .env.example .env
# Éditer .env avec vos paramètres PostgreSQL
```

### 3. Créer la base de données PostgreSQL

```bash
# Option 1: Via psql
psql -U postgres -f scripts/create_schema.sql

# Option 2: Manuellement
psql -U postgres
CREATE DATABASE hotels_db;
\c hotels_db
\i scripts/create_schema.sql
```

## 📖 Utilisation

### Collecter avec OpenStreetMap (GRATUIT)

```python
from collectors.osm_collector import OSMCollector

collector = OSMCollector()

# Collecter tous les hébergements d'une région
total = collector.collect_region("Paris", radius_km=20)
print(f"✓ {total} établissements collectés")
```

### Collecter avec Booking.com

```python
from collectors.booking_scraper import BookingScraper

scraper = BookingScraper(headless=True)

try:
    # Collecter une ville
    total = scraper.collect_city("Lyon")
    print(f"✓ {total} hôtels collectés")
finally:
    scraper.close()
```

### Via ligne de commande

```bash
# OpenStreetMap
python -c "from collectors.osm_collector import OSMCollector; OSMCollector().collect_region('Nice', 30)"

# Booking.com
python -c "from collectors.booking_scraper import BookingScraper; s = BookingScraper(); s.collect_city('Bordeaux'); s.close()"
```

## 🎯 Avantages des Sources Gratuites

### OpenStreetMap
- ✅ **100% gratuit** - Pas de limite
- ✅ **Données ouvertes** - Contributeurs mondiaux
- ✅ **Complet** - Millions d'établissements
- ✅ **Géolocalisé** - Coordonnées GPS précises
- ⚠️ Qualité variable selon les régions

### Booking.com Scraper
- ✅ **Données riches** - Prix, notes, avis
- ✅ **Actualisées** - Informations récentes
- ✅ **Prestations détaillées** - Services complets
- ⚠️ Scraping respectueux (délais entre requêtes)
- ⚠️ Nécessite ChromeDriver

## 📦 Structure du Projet

```
SCRAP/
├── collectors/
│   ├── osm_collector.py        # Collecteur OpenStreetMap
│   ├── booking_scraper.py      # Scraper Booking.com
│   └── __init__.py
├── matching/                   # Moteur de scoring
├── api/                        # API REST FastAPI
├── dashboard/                  # Dashboard Streamlit
├── scripts/                    # Scripts SQL
│   └── create_schema.sql
├── data/                       # Exports
├── config.py                   # Configuration
├── requirements.txt            # Dépendances
├── .env.example               # Template config
└── README.md
```

## 🔧 Configuration Minimale

Fichier `.env`:
```env
# PostgreSQL (obligatoire)
DB_NAME=hotels_db
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe
DB_HOST=localhost
DB_PORT=5432

# Aucune clé API nécessaire !
```

## 🛠️ Installer ChromeDriver (pour Booking)

### macOS
```bash
brew install chromedriver
```

### Linux
```bash
sudo apt-get install chromium-chromedriver
```

### Windows
Télécharger depuis: https://chromedriver.chromium.org/

Ou utiliser webdriver-manager (automatique) :
```python
from webdriver_manager.chrome import ChromeDriverManager
```

## 📊 Exemples Complets

### Script de Collecte Multi-Sources

```python
from collectors.osm_collector import OSMCollector
from collectors.booking_scraper import BookingScraper

# 1. Collecter avec OSM
osm = OSMCollector()
osm_total = osm.collect_region("Marseille", radius_km=25)

# 2. Compléter avec Booking
booking = BookingScraper()
try:
    booking_total = booking.collect_city("Marseille")
finally:
    booking.close()

print(f"""
Collecte terminée pour Marseille:
- OpenStreetMap: {osm_total} établissements
- Booking.com: {booking_total} hôtels
- Total: {osm_total + booking_total}
""")
```

### Collecter Toutes les Grandes Villes

```python
from collectors.osm_collector import OSMCollector

villes = ["Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Bordeaux"]

collector = OSMCollector()
total_general = 0

for ville in villes:
    print(f"\n🏙️  Collecte de {ville}...")
    total = collector.collect_region(ville, radius_km=15)
    total_general += total
    print(f"✓ {total} établissements")

print(f"\n🎉 Total: {total_general} établissements collectés !")
```

## 🌟 Fonctionnalités Principales

- ✅ Collecte automatisée multi-sources
- ✅ Scoring et classification des leads
- ✅ Base de données PostgreSQL
- ✅ Déduplication intelligente
- ✅ Export CSV/JSON
- ✅ API REST (FastAPI)
- ✅ Dashboard web (Streamlit)

## ⚡ Quick Start

```bash
# 1. Installer
pip install -r requirements.txt

# 2. Config
cp .env.example .env
nano .env  # Configurer PostgreSQL

# 3. Base de données
psql -U postgres -f scripts/create_schema.sql

# 4. Collecter !
python -c "from collectors.osm_collector import OSMCollector; OSMCollector().collect_region('Paris', 20)"
```

## 📝 Notes Importantes

### Limites d'Utilisation

**OpenStreetMap/Nominatim:**
- Respecter un délai de 1 seconde entre requêtes
- Ajouter un User-Agent personnalisé
- Lire la politique d'utilisation: https://operations.osmfoundation.org/policies/nominatim/

**Booking.com:**
- Scraping pour usage personnel uniquement
- Respecter robots.txt
- Délais importants entre requêtes
- Ne pas surcharger les serveurs

### Bonnes Pratiques

- ✅ Commencer avec des petites zones (une ville)
- ✅ Augmenter progressivement le périmètre
- ✅ Préférer OSM pour la volumétrie
- ✅ Utiliser Booking pour enrichir les données

## 🆘 Support

- Documentation OpenStreetMap: https://wiki.openstreetmap.org/
- Forum OSM: https://forum.openstreetmap.org/
- Overpass API: https://overpass-turbo.eu/

## 📜 License

MIT License - Données OSM sous ODbL

---

**🎉 Profitez de millions de données GRATUITES !**
