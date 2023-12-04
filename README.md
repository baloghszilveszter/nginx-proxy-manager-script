# Nginx Proxy Manager Script

Ez a script lehetővé teszi a Nginx Proxy Manager használatát hostok létrehozásához, törléséhez és ellenőrzéséhez a parancssorban. A script segítségével egyszerűen kezelheti az Nginx Proxy Manager konfigurációját.

## Telepítés

1. Klónozza le a GitHub tárolót a saját gépére:

   ```sh
   git clone https://github.com/your-username/nginx-proxy-manager-script.git
   ```

2. Lépjen be a projekt mappájába:

   ```
   cd nginx-proxy-manager-script
   ```

3. Indítsa el a scriptet a megfelelő paraméterekkel:

   ```
   ./nginx-proxy-manager.sh <művelet> [domain_name] [forward_scheme] [forward_host] [forward_port] [advanced_config] [ssl_force] [certificate_name] [allow_websocket_upgrade]
   ```

## Használat

A script az alábbi műveletekhez használható:

- create: Új Nginx host létrehozása a megadott paraméterekkel.
- delete: Létező Nginx host törlése a megadott domain név alapján.
- check: Ellenőrizze a meglévő Nginx host-okat és törölje azokat, amelyek nem válaszolnak megfelelően.

## Példák

Host létrehozása:
   ```
   ./nginx-proxy-manager.sh create example.com http 1.1.1.1 80 "" true "*.example.com" true
   ```
Licenc
Ez a script nyílt forráskódú szoftver, és a MIT licenc alatt érhető el.
Host törlése:
   ```
   ./nginx-proxy-manager.sh delete example.com
   ```
   
Host-ok ellenőrzése és szükség esetén törlése:
   ```
   ./nginx-proxy-manager.sh check
   ```
## Figyelem

- Győződjön meg róla, hogy a scripthez megfelelő jogosultságai vannak a futtatáshoz.
- A script az Nginx Proxy Manager alkalmazáshoz csatlakozik, és a műveletek végrehajtásához szüksége van egy munkamenet tokenre. **A bejelentkezéshez szükséges adatokat a script elején kell megadni.**
- Az Nginx Proxy Manager alkalmazásnak elérhetőnek kell lennie a megadott címen és porton.

## Licenc

Ez a script nyílt forráskódú szoftver, és a MIT licenc alatt érhető el.