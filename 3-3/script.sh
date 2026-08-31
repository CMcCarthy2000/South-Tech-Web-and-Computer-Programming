#!/bin/bash

# Configuration
HTML_FILE="index.html"
TMP_JSON="/tmp/rover_telemetry.json"
TMP_IMG_JSON="/tmp/rover_image.json"
LOCAL_IMAGE_NAME="latest_mars.jpg"

# Telemetry URL Sources
SOURCE_1="https://nasa.gov"
SOURCE_2="https://githubusercontent.com"

# NASA Open Photo Endpoint (Uses official public demo key)
PHOTO_API="https://api.nasa.gov/mars-photos/api/v1/rovers/perseverance/latest_photos?api_key=DEMO_KEY"

# Function to inject data safely into index.html
update_html() {
    local lat=$1
    local lon=$2
    local dist=$3
    local sol=$4
    local msg=$5
    local img_path=$6

    # Replace coordinate data inside target spans
    sed -i -E "s|(<span id=\"rover-status\">)[^<]*|\\1$msg|" "$HTML_FILE"
    sed -i -E "s|(<span id=\"rover-lat\">)[^<]*|\\1$lat|" "$HTML_FILE"
    sed -i -E "s|(<span id=\"rover-lon\">)[^<]*|\\1$lon|" "$HTML_FILE"
    sed -i -E "s|(<span id=\"rover-dist\">)[^<]*|\\1$dist|" "$HTML_FILE"
    sed -i -E "s|(<span id=\"rover-sol\">)[^<]*|\\1$sol|" "$HTML_FILE"
    
    # Replace the image src reference path natively
    if [ ! -z "$img_path" ]; then
        sed -i -E "s|(<img id=\"rover-img\" src=\")[^\"]*|\\1$img_path|" "$HTML_FILE"
    fi
    
    echo "SUCCESS: index.html rewritten via [$msg]"
}

echo "Beginning multi-source telemetry sync operations..."

# ==========================================
# STEP 1: FETCH LATEST MARS IMAGE DATA
# ==========================================
DOWNLOADED_IMG_PATH=""
echo "Contacting NASA Photo Registry..."
if curl -s --connect-timeout 8 "$PHOTO_API" > "$TMP_IMG_JSON" && [ -s "$TMP_IMG_JSON" ]; then
    # Grab the top img_src URL parameter out of the latest_photos collection array
    REMOTE_IMG_URL=$(jq -r '.latest_photos[0].img_src' "$TMP_IMG_JSON" 2>/dev/null)
    
    if [ "$REMOTE_IMG_URL" != "null" ] && [ ! -z "$REMOTE_IMG_URL" ]; then
        echo "Image located. Downloading: $REMOTE_IMG_URL"
        # Download the file to your computer/server explicitly as latest_mars.jpg
        if curl -s -o "$LOCAL_IMAGE_NAME" "$REMOTE_IMG_URL"; then
            DOWNLOADED_IMG_PATH="$LOCAL_IMAGE_NAME"
            echo "Image downloaded locally as: $LOCAL_IMAGE_NAME"
        fi
    fi
fi
rm -f "$TMP_IMG_JSON"

# ==========================================
# STEP 2: CHOOSE AND MAP STREAM TELEMETRY
# ==========================================

# --- ATTEMPT 1: NASA JPL Live Data Layer ---
echo "Contacting Source 1: NASA telemetry server..."
if curl -s --connect-timeout 8 "$SOURCE_1" > "$TMP_JSON" && [ -s "$TMP_JSON" ]; then
    LON=$(jq -r '.features[-1].geometry.coordinates[0]' "$TMP_JSON" 2>/dev/null)
    LAT=$(jq -r '.features[-1].geometry.coordinates[1]' "$TMP_JSON" 2>/dev/null)
    DIST_M=$(jq -r '.features[-1].properties.dist_total' "$TMP_JSON" 2>/dev/null)
    SOL=$(jq -r '.features[-1].properties.sol' "$TMP_JSON" 2>/dev/null)
    
    if [ "$LAT" != "null" ] && [ ! -z "$LAT" ]; then
        DIST=$(echo "scale=2; $DIST_M / 1000" | bc 2>/dev/null || echo "44.98")
        update_html "$LAT" "$LON" "$DIST" "$SOL" "Official NASA Data Feed" "$DOWNLOADED_IMG_PATH"
        rm -f "$TMP_JSON"
        exit 0
    fi
fi

# --- ATTEMPT 2: Open Source Community Mirror ---
echo "Source 1 down or blocked. Contacting Source 2: GitHub Action Mirror..."
if curl -s --connect-timeout 8 "$SOURCE_2" > "$TMP_JSON" && [ -s "$TMP_JSON" ]; then
    LON=$(jq -r '.features[-1].geometry.coordinates[0]' "$TMP_JSON" 2>/dev/null)
    LAT=$(jq -r '.features[-1].geometry.coordinates[1]' "$TMP_JSON" 2>/dev/null)
    DIST_RAW=$(jq -r '.features[-1].properties.distance // .features[-1].properties.dist_total' "$TMP_JSON" 2>/dev/null)
    SOL=$(jq -r '.features[-1].properties.sol' "$TMP_JSON" 2>/dev/null)

    if [ "$LAT" != "null" ] && [ ! -z "$LAT" ]; then
        DIST=$(echo "$DIST_RAW" | awk '{if ($1 > 1000) printf "%.2f", $1/1000; else printf "%.2f", $1}')
        update_html "$LAT" "$LON" "$DIST" "$SOL" "Community Mirror Sync" "$DOWNLOADED_IMG_PATH"
        rm -f "$TMP_JSON"
        exit 0
    fi
fi

# --- ATTEMPT 3: Local Fail-Safe State Engine ---
echo "All external telemetry streams timed out. Booting offline local telemetry state..."
update_html "18.44700" "77.40200" "44.98" "1960+" "Local Hardcoded Fallback" "$DOWNLOADED_IMG_PATH"
rm -f "$TMP_JSON"
