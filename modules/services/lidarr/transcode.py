import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
import re
import shutil
import subprocess
import threading


COMPRESSED_LOSSLESS = {
    "alac",
    "ape",
    "flac",
    "wavpack",
}

PCM_PREFIXES = ("pcm_", "dsd_")

VALID_EXTENSIONS = [
    ".aac",
    ".alac",
    ".ape",
    ".flac",
    ".m4a",
    ".mp3",
    ".ogg",
    ".wav",
    ".wma",
]


print_lock = threading.Lock()


def log(message):
    with print_lock:
        print(message)


def check_dependencies():
    for cmd in ["ffmpeg", "ffprobe"]:
        if not shutil.which(cmd):
            print(f"Error: {cmd} is not installed or not in PATH.")
            exit(1)


def get_audio_info(file_path):
    """extract codec and bitrate using ffprobe"""

    try:
        cmd = (
            [
                "ffprobe",
                "-v",
                "quiet",
            ]
            # stream selection & metadata
            + [
                "-select_streams",
                "a:0",
                "-show_entries",
                "stream=codec_name:format=bit_rate",
            ]
            # output format & file path
            + [
                "-of",
                "json",
                file_path,
            ]
        )

        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )

        data = json.loads(result.stdout)

        codec = data.get("streams", [{}])[0].get("codec_name", "")
        bitrate = data.get("format", {}).get("bit_rate", "")

        return codec, bitrate

    except Exception:
        return "", ""


def get_loudness(file_path):
    """measure integrated loudness using ffmpeg loudnorm filter"""

    try:
        cmd = (
            [
                "ffmpeg",
                "-nostdin",
                "-i",
                file_path,
            ]
            + [
                # disable video / subtitles & loudness filter
                "-vn",
                "-sn",
                "-filter:a",
                "loudnorm=print_format=json",
            ]
            + [
                # null output (discards file but print)
                "-f",
                "null",
                "-",
            ]
        )

        result = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )

        # look for json output block inside stderr
        match = re.search(r'"input_i"\s*:\s*"([^"]+)"', result.stderr)

        if match:
            return float(match.group(1))

    except Exception:
        pass

    return -99.0


def process_audio(file_path):
    output_lines = ["==================================================="]
    output_lines.append(f"Processing: {file_path}")

    codec, bitrate = get_audio_info(file_path)

    # extract file extension
    _, ext = os.path.splitext(file_path)
    ext_lower = ext.lstrip(".").lower()

    measured_loudness = get_loudness(file_path)
    output_lines.append(
        f"--> Measured integrated loudness: {measured_loudness} LUFS"
    )

    # target -14.0 LUFS with small tolerance (-15.0 to -13.0)
    needs_normalization = False

    if -15.0 <= measured_loudness <= -13.0:
        output_lines.append("--> Audio is already normalized.")
        needs_normalization = False
    else:
        output_lines.append(
            "--> Audio is not normalized. Applying loudnorm filter."
        )
        needs_normalization = True

    # set output file
    base_path, _ = os.path.splitext(file_path)
    output_file = f"{base_path}.tmp.ogg"
    final_output_file = f"{base_path}.ogg"

    # skip if already opus ogg and normalized
    if codec == "opus" and ext_lower == "ogg" and not needs_normalization:
        output_lines.append("--> File is already properly transcoded.")
        output_lines.append(
            "==================================================="
        )
        log("\n".join(output_lines))
        return

    # determine encoder and target bitrate based on codec
    needs_transcoding = False
    target_bitrate = None

    if codec == "opus":
        output_lines.append("--> Audio is already Opus.")
        if needs_normalization:
            needs_transcoding = True

            if bitrate.isdigit():
                target_bitrate = bitrate
            else:
                target_bitrate = "128000"

            output_lines.append(
                "--> Re-encoding to apply loudness normalization."
            )
        else:
            needs_transcoding = False

            output_lines.append("--> Stream copying audio to OGG container.")

    elif codec in COMPRESSED_LOSSLESS or codec.startswith(PCM_PREFIXES):
        output_lines.append(f"--> Detected lossless ({codec}).")

        needs_transcoding = True
        target_bitrate = "256000"
    else:
        if bitrate.isdigit():
            target_bps = int(bitrate) // 2

            if target_bps < 64000:
                target_bps = 64000

            needs_transcoding = True
            target_bitrate = str(target_bps)

            output_lines.append(
                f"--> Found ({codec}) at {int(bitrate) // 1000}k."
            )
        else:
            needs_transcoding = True
            target_bitrate = "64000"

            output_lines.append(f"--> Could not get bitrate for ({codec}).")

    if target_bitrate:
        output_lines.append(f"--> Target bitrate: {target_bps // 1000}k")

    ffmpeg_codec = (
        ["-c:a", "libopus"] if needs_transcoding else ["-c:a", "copy"]
    )

    bitrate_flags = (
        ["-b:a", target_bitrate]
        if target_bitrate and needs_transcoding
        else []
    )

    ffmpeg_filter = (
        ["-af", "loudnorm=I=-14:TP=-1:LRA=11"] if needs_normalization else []
    )

    cmd = (
        [
            "ffmpeg",
            "-nostdin",
            "-v",
            "quiet",
        ]
        + [
            "-i",
            file_path,
        ]
        + [
            # stream mapping
            "-map",
            "0:a",
            # metadata copying
            "-map_metadata",
            "0",
        ]
        + ffmpeg_codec
        + bitrate_flags
        + ffmpeg_filter
        + [
            "-y",
            output_file,
        ]
    )

    # execute conversion
    try:
        subprocess.run(cmd, check=True)

        os.remove(file_path)
        shutil.move(output_file, final_output_file)

        output_lines.append("--> Successfully processed audio file.")
        output_lines.append("--> Deleted original file.")

        output_lines.append(f"--> Saved as: {final_output_file}")

    except subprocess.CalledProcessError:
        output_lines.append(f"--> Error converting {file_path}.")

        if os.path.exists(output_file):
            os.remove(output_file)

    output_lines.append(
        "===================================================\n"
    )
    log("\n".join(output_lines))


def main():
    check_dependencies()

    parser = argparse.ArgumentParser(
        description="Multithreaded Audio Transcoder to Opus OGG"
    )

    parser.add_argument(
        "--recursive",
        "-r",
        action="store_true",
        help="Search directories recursively",
    )

    parser.add_argument(
        "--parallel",
        "-p",
        nargs="?",
        const=4,
        type=int,
        help="Number of parallel threads",
    )

    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Directory or file path to process",
    )

    args = parser.parse_args()

    files_to_process = []
    target_path = args.path

    # case single file
    if os.path.isfile(target_path):
        _, ext = os.path.splitext(target_path)

        if ext.lower() in VALID_EXTENSIONS:
            files_to_process.append(target_path)

    # case directory
    elif os.path.isdir(target_path):
        # recursively all files
        if args.recursive:
            for root, _, files in os.walk(target_path):
                for file in files:
                    _, ext = os.path.splitext(file)

                    if ext.lower() in VALID_EXTENSIONS:
                        files_to_process.append(os.path.join(root, file))

        # only current directory
        else:
            for file in os.listdir(target_path):
                full_path = os.path.join(target_path, file)

                if os.path.isfile(full_path):
                    _, ext = os.path.splitext(file)

                    if ext.lower() in VALID_EXTENSIONS:
                        files_to_process.append(full_path)

    if not files_to_process:
        print("No matching audio files found.")
        return
    else:
        print(f"Found {len(files_to_process)} audio files to process.")

    # handle threading allocation
    if args.parallel is not None:
        max_workers = args.parallel
        print(f"Processing in parallel using {max_workers} threads...")

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            executor.map(process_audio, files_to_process)
    else:
        print("Processing sequentially...")
        for file in files_to_process:
            process_audio(file)


if __name__ == "__main__":
    main()
