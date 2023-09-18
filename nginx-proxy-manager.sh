#!/bin/bash

# Nginx Proxy Manager host IP cime és portja
HOST_IP="192.168.1.100"
HOST_PORT="81"

# Bejelentkezes az Nginx Proxy Manager alkalmazasba
SESSION_TOKEN=$(curl -s -X POST "http://$HOST_IP:$HOST_PORT/api/tokens" -H "Content-Type: application/json" -d '{
  "identity": "user@example.com",
  "secret": "PASSWORD"
}' | jq -r '.token')

# Ellenorizze, hogy sikerult-e bejelentkezni, es van-e token
if [ -z "$SESSION_TOKEN" ]; then
  echo "Nem sikerult bejelentkezni az Nginx Proxy Manager alkalmazasba."
  exit 1
fi

# Ellenorizze, hogy legalabb egy argumentumot megadtak-e
if [ $# -lt 1 ]; then
  echo "Hasznalat: $0 <create/delete/check> [domain_name] [forward_scheme] [forward_host] [forward_port] [advanced_config] [ssl_force]"
  exit 1
fi

# Elso argumentum: create, delete vagy check
ACTION="$1"

# Az Nginx host letrehozasa
if [ "$ACTION" == "create" ]; then
  # Ellenorzi, hogy legalabb a minimalis parametereket megadtak-e
  if [ $# -lt 7 ]; then
    echo "Hianyzo parameterek a host letrehozasahoz."
    echo "Hasznalat: $0 create <domain_name> <forward_scheme> <forward_host> <forward_port> <advanced_config> <ssl_force>"
    exit 1
  fi

  DOMAIN_NAME="$2"
  FORWARD_SCHEME="$3"
  FORWARD_HOST="$4"
  FORWARD_PORT="$5"
  ADVANCED_CONFIG="$6"
  SSL_FORCE="$7"

  # Uj szabaly letrehozasa az Nginx Proxy Manager alkalmazasban
  curl -s -X POST "http://$HOST_IP:$HOST_PORT/api/nginx/proxy-hosts" -H "Content-Type: application/json" -H "Authorization: Bearer $SESSION_TOKEN" -d '{
    "domain_names":["'"$DOMAIN_NAME"'"],
    "forward_scheme":"'"$FORWARD_SCHEME"'",
    "forward_host":"'"$FORWARD_HOST"'",
    "forward_port":'"$FORWARD_PORT"',
    "advanced_config":"'"$ADVANCED_CONFIG"'",
    "ssl_forced":'"$SSL_FORCE"'
  }'
  echo "Nginx host letrehozva: $DOMAIN_NAME"

# Az Nginx host torlese
elif [ "$ACTION" == "delete" ]; then
  # Ellenorzi, hogy megadtak-e a domain nevet a torleshez
  if [ $# -lt 2 ]; then
    echo "Hianyzo parameter a host torlesehez."
    echo "Hasznalat: $0 delete <domain_name>"
    exit 1
  fi

  DOMAIN_NAME="$2"

  # Host ID keresese a domain nev alapjan
  HOST_ID=$(curl -s "http://$HOST_IP:$HOST_PORT/api/nginx/proxy-hosts" -H "Authorization: Bearer $SESSION_TOKEN" | jq -r '.[] | select(.domain_names | contains(["'"$DOMAIN_NAME"'"])) | .id')

  # Ellenorzi, hogy talalt-e host ID-t a domain nev alapjan
  if [ -z "$HOST_ID" ]; then
    echo "Nem talalhato host a kovetkezo domain nevvel: $DOMAIN_NAME"
    exit 1
  fi

  # Host torlese az Nginx Proxy Manager alkalmazasbol
  curl -s -X DELETE "http://$HOST_IP:$HOST_PORT/api/nginx/proxy-hosts/$HOST_ID" -H "Authorization: Bearer $SESSION_TOKEN"
  echo "Nginx host torolve: $DOMAIN_NAME"

# Ellenorzi az Nginx host-okat
elif [ "$ACTION" == "check" ]; then
  # Lekeri az Nginx Proxy Manager hostok listajat es kinyeri a domain_names ertekeket
  DOMAIN_NAMES=($(curl -s -X GET "http://$HOST_IP:$HOST_PORT/api/nginx/proxy-hosts" -H "Content-Type: application/json" -H "Authorization: Bearer $SESSION_TOKEN" | jq -r '.[].domain_names[]'))

  # Ellenorizze, hogy van-e domain_names ertek
  if [ ${#DOMAIN_NAMES[@]} -eq 0 ]; then
    echo "Nincsenek hostok a listan."
    exit 1
  fi

  # Fuggveny az nginx host torlesehez
  delete_nginx_host() {
    local domain_name="$1"

    # Host ID keresese a domain nev alapjan
    HOST_ID=$(curl -s "http://$HOST_IP:$HOST_PORT/api/nginx/proxy-hosts" -H "Authorization: Bearer $SESSION_TOKEN" | jq -r '.[] | select(.domain_names | contains(["'"$domain_name"'"])) | .id')

    # Ellenorzi, hogy talalt-e host ID-t a domain nev alapjan
    if [ -z "$HOST_ID" ]; then
      echo "Nem talalhato host a kovetkezo domain nevvel: $domain_name"
    else
      # Host torlese az Nginx Proxy Manager alkalmazasbol
      curl -s -X DELETE "http://$HOST_IP:$HOST_PORT/api/nginx/proxy-hosts/$HOST_ID" -H "Authorization: Bearer $SESSION_TOKEN"
      echo "Nginx host torolve: $domain_name"
    fi
  }

  # A DOMAIN_NAMES tomb tartalmazza a domain_names ertekeket, most itt feldolgozhatja oket
  for DOMAIN_NAME in "${DOMAIN_NAMES[@]}"; do
    echo "Ellenorzes: $DOMAIN_NAME"

    # Ellenorzes HTTP-re
    RESPONSE_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN_NAME")

    # Ellenorzes HTTPS-re
    RESPONSE_HTTPS=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN_NAME")

    # Ellenorzi a valasz kodjat (nem 200 vagy 301)
    if [ "$RESPONSE_HTTP" != "200" ] && [ "$RESPONSE_HTTP" != "301" ] && [ "$RESPONSE_HTTPS" != "200" ] && [ "$RESPONSE_HTTPS" != "301" ]; then
      echo "Hiba: Nem sikerult elerni a $DOMAIN_NAME webhelyet (HTTP: $RESPONSE_HTTP, HTTPS: $RESPONSE_HTTPS). A host torlesre kerul."
      delete_nginx_host "$DOMAIN_NAME"
    else
      echo "Sikeres ellenorzes: $DOMAIN_NAME (HTTP: $RESPONSE_HTTP, HTTPS: $RESPONSE_HTTPS)"
    fi
  done
else
  echo "Ismeretlen muvelet: $ACTION"
  exit 1
fi
