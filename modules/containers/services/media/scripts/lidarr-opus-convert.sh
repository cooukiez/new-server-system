#!/usr/bin/env bash

# exit on error
set -e

LOGFILE="/log/lidarr_opus_convert.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "--- Lidarr Event Triggered: $lidarr_eventtype ---"

# handle events
if [ "$lidarr_eventtype" = "Test" ]; then
    echo "Test event detected. Script will run in simulation/dry-run mode (original files will not be deleted)."

    if [ -z "$lidarr_trackfile_paths" ]; then
        lidarr_trackfile_paths="/tmp/test_lidarr_audio.flac"
        ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 "$lidarr_trackfile_paths" > /dev/null 2>&1
    fi
elif [ "$lidarr_eventtype" != "Rename" ]; then
    echo "Event type is not Rename."
    exit 0
fi

# lidarr passes multiple files separated by pipe
IFS='|' read -r -a TRACK_PATHS <<< "$lidarr_trackfile_paths"

for FILE_PATH in "${TRACK_PATHS[@]}"; do
    if [ ! -f "$FILE_PATH" ]; then
        echo "File not found: $FILE_PATH"
        continue
    fi

    echo "Processing: $FILE_PATH"

    # get file extension in lowercase
    EXTENSION="${FILE_PATH##*.}"
    EXTENSION=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

    # if already opus file, skip
    if [ "$EXTENSION" = "opus" ]; then
        echo "File is already Opus."
        continue
    fi

    # determine target bitrate
    TARGET_BITRATE="128k" # default
    
    if [[ "$EXTENSION" == "flac" || "$EXTENSION" == "wav" || "$EXTENSION" == "alac" ]]; then
        # lossless files get the maximum quality requested
        TARGET_BITRATE="256k"
        echo "Detected Lossless ($EXTENSION). Targeting 256k Opus."
    else
        # extract current overall bitrate using ffprobe for lossy files
        ORIG_BITRATE=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nocut=1 "$FILE_PATH" | cut -d= -f2 || echo "")

        if [ -z "$ORIG_BITRATE" ] || [ "$ORIG_BITRATE" = "N/A" ]; then
            echo "Could not detect bitrate. Defaulting to 128k Opus."
            TARGET_BITRATE="128k"
        else
            # convert bits to kbps
            ORIG_KBPS=$((ORIG_BITRATE / 1000))
            echo "Detected Lossy ($EXTENSION) with bitrate: ${ORIG_KBPS}kbps"

            if [ "$ORIG_KBPS" -ge 320 ]; then
                TARGET_BITRATE="128k"
            elif [ "$ORIG_KBPS" -ge 256 ]; then
                TARGET_BITRATE="112k"
            elif [ "$ORIG_KBPS" -ge 192 ]; then
                TARGET_BITRATE="96k"
            elif [ "$ORIG_KBPS" -ge 128 ]; then
                TARGET_BITRATE="64k"
            else
                TARGET_BITRATE="48k"
            fi
        fi
        echo "Targeting ${TARGET_BITRATE} Opus to preserve quality/size ratio."
    fi

    NEW_FILE_PATH="${FILE_PATH%.*}.opus"

    # convert and transfer metadata
    echo "Converting..."
    set +e
    ffmpeg -y -i "$FILE_PATH" -c:a libopus -b:a "$TARGET_BITRATE" -vbr on -map_metadata 0 "$NEW_FILE_PATH"
    FFMPEG_STATUS=$?
    set -e

    if [ $FFMPEG_STATUS -eq 0 ]; then
        echo "Conversion successful: $NEW_FILE_PATH"
        
        if [ "$lidarr_eventtype" = "Test" ]; then
            echo "[TEST MODE] Skipping deletion of original file: $FILE_PATH"
        else
            echo "Removing original file: $FILE_PATH"
            rm "$FILE_PATH"
        fi
    else
        echo "Error: Conversion failed for $FILE_PATH"
    fi
done

echo "--- Finished Processing ---"