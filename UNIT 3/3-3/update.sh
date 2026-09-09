#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )"
MSG_FILE="$SCRIPT_DIR/message.txt"
PORT=8000

echo "========================================================"
echo "LAUNCHING INTERACTIVE BASH SERVER VIA PORT $PORT"
echo "========================================================"
echo "📡 Listening for background web requests natively..."
echo "👉 Open your browser to http://localhost:$PORT to test connection!"

PACKET_COUNTER=0
echo "[$PACKET_COUNTER] Awaiting connection..." > "$MSG_FILE"

# Micro webserver loop running purely on basic command tools
while true; do
    # Listen on port 8000 for incoming browser handshake signals
    # Respond with correct HTTP/1.1 headers so the browser accepts the raw data blocks
    (echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-cache\r\n\r\n"; cat "$MSG_FILE") | nc -l -p $PORT -q 1 2>/dev/null
    
    # Prompt the user for input messages
    echo ""
    read -p "Type a sentence to display on the webpage: " USER_INPUT
    
    if [ ! -z "$USER_INPUT" ]; then
        PACKET_COUNTER=$(( PACKET_COUNTER + 1 ))
        # Overwrite the shared file mapping payload safely
        echo "[$PACKET_COUNTER] $USER_INPUT" > "$MSG_FILE"
        echo "📡 DATA SENT: Broadcasted verification packet #$PACKET_COUNTER"
    fi
done
