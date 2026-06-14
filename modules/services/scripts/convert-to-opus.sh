#!/usr/bin/env bash

# ensure ffmpeg and ffprobe are installed
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "Error: ffmpeg and ffprobe not installed."
    exit 1
fi

# exclude ogg files to prevent reencoding files
find . -type f \( -iname "*.aac" -o -iname "*.alac" -o -iname "*.ape" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.mp3" -o -iname "*.wav" -o -iname "*.wma" \) ! -iname "*.ogg" -print0 | while IFS= read -r -d '' file; do

    echo "Processing: $file"

    # extract codec and bitrate using ffprobe
    codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" | head -n 1)
    bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file")

    # determine target bitrate based on codec
    if [[ "$codec" =~ ^(alac|ape|flac|pcm_f32le|pcm_s16le|pcm_s24le|pcm_s32le|wavpack)$ ]]; then
        # lossless format
        target_bitrate="256k"
        echo "--> Detected lossless ($codec). Target bitrate: $target_bitrate"
    else
        # lossy format
        if [[ "$bitrate" =~ ^[0-9]+$ ]]; then
            target_bps=$((bitrate / 2))
            target_bitrate="${target_bps}"
            echo "--> Detected lossy ($codec) at $((bitrate / 1000))k. Target bitrate: $((target_bps / 1000))k"
        else
            # fallback
            target_bitrate="64k"
            echo "--> Could not detect bitrate for lossy ($codec). Defaulting to: $target_bitrate"
        fi
    fi

    output_file="${file%.*}.ogg"

    # execute ffmpeg conversion
    # -c:a libopus      : use the opus audio encoder
    # -b:a              : set the target audio bitrate
    # -vbr on           : use variable bitrate
    # -map_metadata 0   : copy all global metadata from input to output
    # -y                : overwrite output file if it exists without asking

    if ffmpeg -v error -stats -i "$file" -c:a libopus -b:a "$target_bitrate" -vbr on -map_metadata 0 -y "$output_file"; then
        echo "--> Successfully transcoded the audio file to opus!"
        echo "--> Deleting original file."
        # rm "$file"
    else
        echo "--> Error converting $file. Original file has been kept safe."
    fi

    echo "---------------------------------------------------"
done

echo "All audio files have been converted to Opus!"