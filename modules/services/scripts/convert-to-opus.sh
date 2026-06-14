#!/usr/bin/env bash

if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "Error: ffmpeg and ffprobe not installed."
    exit 1
fi

if ! command -v parallel &> /dev/null; then
    echo "Error: GNU parallel is not installed for multithreading."
    exit 1
fi

process_audio() {
    file="$1"
    echo "==================================================="
    echo "Processing: $file"

    # extract codec and bitrate using ffprobe
    codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" < /dev/null | head -n 1)
    bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" < /dev/null)
    
    # extract current file extension lowercased
    ext="${file##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # measure integrated loudness
    measured_loudness=$(ffmpeg -nostdin -i "$file" -vn -sn -filter:a loudnorm=print_format=json -f null - 2>&1 | awk -F'"' '/input_i/ {print $4}')

    if [[ ! "$measured_loudness" =~ ^-[0-9]+(\.[0-9]+)?$ ]]; then
        # default low number to force normalization if detection fails
        measured_loudness="-99"
    fi

    echo "--> Measured integrated loudness: ${measured_loudness} LUFS"
        
    # target is -14.0 LUFS
    loudness_int=$(printf "%.0f" "$measured_loudness" 2>/dev/null || echo "-99")
    
    # allow small tolerance window around -14 LUFS (-15.0 to -13.0)
    if [ "$loudness_int" -ge -15 ] && [ "$loudness_int" -le -13 ]; then
        echo "--> Audio is already normalized."
        needs_normalization=false
        ffmpeg_filter=""
    else
        echo "--> Audio is not normalized. Applying loudnorm filter."
        needs_normalization=true
        ffmpeg_filter="-af loudnorm=I=-14:TP=-1:LRA=11"
    fi

    # check if we can safely skip this file completely (Updated target container check to ogg)
    if [[ "$codec" == "opus" ]] && [ "$ext_lower" == "ogg" ] && [ "$needs_normalization" = false ]; then
        echo "--> File is already properly transcoded."
        echo "==================================================="
        return 0
    fi

    # determine encoder and target bitrate based on codec
    if [[ "$codec" == "opus" ]]; then
        echo "--> Audio is already Opus."
        if [ "$needs_normalization" = true ]; then
            # if it needs normalization, we must re-encode it
            ffmpeg_codec="-c:a libopus"

            # attempt to retain its original bitrate or fallback to 128k for standard opus
            if [[ "$bitrate" =~ ^[0-9]+$ ]]; then
                target_bitrate="$bitrate"
            else
                target_bitrate="128000"
            fi

            echo "--> Re-encoding to apply loudness normalization. Target bitrate: $((target_bitrate / 1000))k"
        else
            # already normalized, just needs to change container to ogg
            echo "--> Container change needed ($ext_lower -> ogg). Stream copying audio without re-encoding."

            ffmpeg_codec="-c:a copy"
            target_bitrate=""
            ffmpeg_filter=""
        fi
    elif [[ "$codec" =~ ^(alac|ape|flac|pcm_f32le|pcm_s16le|pcm_s24le|pcm_s32le|wavpack)$ ]]; then
        # lossless format
        echo "--> Detected lossless ($codec)."

        ffmpeg_codec="-c:a libopus"
        target_bitrate="256000"
    else
        # lossy format
        ffmpeg_codec="-c:a libopus"

        if [[ "$bitrate" =~ ^[0-9]+$ ]]; then
            target_bps=$((bitrate / 2))

            # floor limit 64k
            if [ $target_bps -lt 64000 ]; then target_bps=64000; fi

            target_bitrate="${target_bps}"
            echo "--> Detected lossy ($codec) at $((bitrate / 1000))k. Target bitrate: $((target_bps / 1000))k"
        else
            # fallback
            target_bitrate="64000"
            echo "--> Could not detect bitrate for lossy ($codec). Defaulting to: $target_bitrate"
        fi
    fi

    output_file="${file%.*}.trans.ogg"

    # prepare bitrate flags if encoding
    bitrate_flags=""
    if [ -n "$target_bitrate" ] && [ "$ffmpeg_codec" != "-c:a copy" ]; then
        bitrate_flags="-b:a $target_bitrate"
    fi

    # execute ffmpeg conversion
    # -map 0:a : copy only audio streams
    # -map_metadata 0 : copy all global metadata from input to output
    # -y : overwrite output file, if it exists, without asking

    if ffmpeg -nostdin -v quiet -stats -i "$file" \
        -map 0:a $ffmpeg_codec $bitrate_flags $ffmpeg_filter \
        -map_metadata 0 -y "$output_file"; then
        
        echo "--> Successfully processed audio file to Opus OGG!"
        echo "--> Saved as: $output_file"

        echo "--> Deleted original file."
        rm "$file"
    else
        echo "--> Error converting $file. Original file has been kept safe."
        [ -f "$output_file" ] && rm "$output_file"
    fi
    echo "==================================================="
}

# export function and variables that they are accessible inside gnu parallel
export -f process_audio

# find all files and pipe them into gnu parallel
find . -type f \( -iname "*.aac" -o -iname "*.alac" -o -iname "*.ape" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.mp3" -o -iname "*.ogg" -o -iname "*.wav" -o -iname "*.wma" \) ! -iname "*.trans.ogg" -print0 | \
parallel -0 --jobs 4 process_audio "{}"

echo "All audio files have been processed to Opus OGG!"