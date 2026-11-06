#!/bin/bash

if [ -z "$1" ]; then
    echo "Uputstvo za upotrebu: $0 <URL>"
    echo "Primer: $0 http://localhost:5000"
    exit 1
fi

URL="$1/health"
MAX_TRIES=5
PAUSE=3

echo "Pokrećem proveru zdravlja aplikacije na $URL..."

for ((i=1; i<=MAX_TRIES; i++)); do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    
    echo "[$TIMESTAMP] Pokušaj $i/$MAX_TRIES - Status: $HTTP_STATUS"
    
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "Aplikacija je zdrava!"
        exit 0
    fi
    
    if [ $i -lt $MAX_TRIES ]; then
        sleep $PAUSE
    fi
done

echo "Greška: Aplikacija nije dostupna ni posle $MAX_TRIES pokušaja."
exit 1