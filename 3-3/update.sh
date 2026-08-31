#!/bin/bash

HTML_FILE="index.html"
TMP_JSON="/tmp/mars_photo.json"
LOCAL_IMAGE="latest_mars.jpg"

# Official NASA API for the absolute newest photos uploaded by Perseverance
PHOTO_API="https://api.nasa.gov/mars-photos/api/v1/rovers/perseverance/latest_photos?api_key=Hk2VkVhzirVqX10NeOXU8Fhm0YMYwPorsbdFmfGQ"

echo "Connecting to NASA Mars Photo Registry..."

# Fetch the photo registry data
if curl -s --connect-timeout 10 "$PHOTO_API" > "$TMP_JSON" && [ -s "$TMP_JSON" ]; then
    
    # FIXED: Added [0] to correctly extract 'img_src' from the first element of the array
    REMOTE_URL=$(jq -r '.latest_photos[0].img_src' "$TMP_JSON" 2>/dev/null)

    # Check if a valid URL was returned (and ensure it's not null, empty, or an error)
    if [ "$REMOTE_URL" != "null" ] && [ ! -z "$REMOTE_URL" ]; then
        echo "Found newest image URL: $REMOTE_URL"
        echo "Downloading image..."
        
        # Download the image file locally
        if curl -s -o "$LOCAL_IMAGE" "$REMOTE_URL"; then
            echo "Success! Saved image locally as '$LOCAL_IMAGE'"
            
            # Update the HTML file to point to the new image
            sed -i -E "s|(<img id=\"rover-img\" src=\")[^\"]*|\\1$LOCAL_IMAGE|" "$HTML_FILE"
            echo "Updated $HTML_FILE successfully."
        else
            echo "ERROR: Failed to download the image file."
        fi
    else
        echo "ERROR: Could not parse a valid image URL from NASA's data."
    fi
else
    echo "ERROR: Failed to connect to NASA's photo API or data was empty."
fi

# Clean up temp files
rm -f "$TMP_JSON"
