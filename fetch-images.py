import subprocess
import json
import os
import re
import sys
import argparse

# nix shell nixpkgs#skopeo nixpkgs#nix-prefetch-docker nixpkgs#python3 -c python3 fetch-images.py

IMAGES = [
    {"name": "ebk", "repo": "docker.io/mayswind/ezbookkeeping", "tag": "latest"},
    {"name": "mail-archiver", "repo": "docker.io/s1t5/mailarchiver", "tag": "latest"},
    {"name": "papra", "repo": "ghcr.io/papra-hq/papra", "tag": "latest"},
    {"name": "radicale", "repo": "docker.io/tomsquest/docker-radicale", "tag": "latest"},
    {"name": "radicale-original", "repo": "ghcr.io/kozea/radicale", "tag": "latest"},
    
    {"name": "jellyfin", "repo": "docker.io/jellyfin/jellyfin", "tag": "latest"},
    {"name": "lidarr", "repo": "lscr.io/linuxserver/lidarr", "tag": "nightly"},
    {"name": "slskd", "repo": "docker.io/slskd/slskd", "tag": "latest"},
    {"name": "qbittorrent", "repo": "lscr.io/linuxserver/qbittorrent", "tag": "latest"},

    {"name": "atuin", "repo": "ghcr.io/atuinsh/atuin", "tag": "latest"},
    {"name": "crontab", "repo": "docker.io/alseambusher/crontab-ui", "tag": "latest"},
    {"name": "gitea", "repo": "docker.gitea.com/gitea", "tag": "latest"},

    {"name": "immich-ml", "repo": "ghcr.io/immich-app/immich-machine-learning", "tag": "release"},
    {"name": "valkey", "repo": "docker.io/valkey/valkey", "tag": "alpine"},
    {"name": "immich-db", "repo": "ghcr.io/immich-app/postgres", "tag": "14-vectorchord0.5.3"},
    {"name": "immich-server", "repo": "ghcr.io/immich-app/immich-server", "tag": "release"},

    {"name": "linkwarden", "repo": "ghcr.io/linkwarden/linkwarden", "tag": "latest"},
    {"name": "memos", "repo": "docker.io/neosmemo/memos", "tag": "stable"},
    {"name": "node-red", "repo": "docker.io/nodered/node-red", "tag": "latest"},
    {"name": "opengist", "repo": "ghcr.io/thomiceli/opengist", "tag": "latest"},
    {"name": "outline", "repo": "docker.io/outlinewiki/outline", "tag": "latest"},
    {"name": "stirling", "repo": "docker.io/stirlingtools/stirling-pdf", "tag": "latest"},
    {"name": "transfer-sh", "repo": "docker.io/dutchcoders/transfer.sh", "tag": "latest"},
    {"name": "trek", "repo": "docker.io/mauriceboe/trek", "tag": "latest"},
    {"name": "vnstat-dashboard", "repo": "docker.io/kshitizb/vnstat-dashboard", "tag": "latest"},

    # core
    {"name": "meili", "repo": "docker.io/getmeili/meilisearch", "tag": "latest"},
    {"name": "redis", "repo": "docker.io/library/redis", "tag": "alpine"},

    {"name": "authelia", "repo": "ghcr.io/authelia/authelia", "tag": "latest"},
    {"name": "borg-ui", "repo": "docker.io/ainullcode/borg-ui", "tag": "latest"},

    {"name": "postgres", "repo": "docker.io/library/postgres", "tag": "alpine"},
    {"name": "pgadmin", "repo": "docker.io/dpage/pgadmin4", "tag": "latest"},

    {"name": "adguard", "repo": "docker.io/adguard/adguardhome", "tag": "latest"},
    {"name": "homepage", "repo": "ghcr.io/gethomepage/homepage", "tag": "latest"},
    {"name": "lldap", "repo": "ghcr.io/lldap/lldap", "tag": "stable"},

    {"name": "grafana", "repo": "docker.io/grafana/grafana-enterprise", "tag": "latest"},
    {"name": "prometheus", "repo": "docker.io/prom/prometheus", "tag": "latest"},
    {"name": "prometheus-podman-exporter", "repo": "quay.io/navidys/prometheus-podman-exporter", "tag": "latest"},
    {"name": "loki", "repo": "docker.io/grafana/loki", "tag": "latest"},

    {"name": "caddy", "repo": "docker.io/library/caddy", "tag": "latest"},
    {"name": "gluetun", "repo": "ghcr.io/qdm12/gluetun", "tag": "latest"},
    {"name": "gluetun-webui", "repo": "docker.io/scuzza/gluetun-webui", "tag": "latest"},
]

LOCK_FILE = "images-lock.json"
NIX_FILE = "generated-images.nix"

def get_remote_digest(repo, tag):
    """fetch the digest using skopeo"""

    cmd = ["skopeo", "inspect", f"docker://{repo}:{tag}"]
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"Error inspecting {repo}:{tag}: {result.stderr}")
        return None

    return json.loads(result.stdout)["Digest"]

def prefetch_nix_hash(repo, digest):
    """get the nix-hash for the specific image digest"""

    cmd = ["nix-prefetch-docker", "--quiet", repo, "--image-digest", digest]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Error prefetching {repo}: {result.stderr}")
        return None

    # nix output no json
    match = re.search(r'(?:hash|sha256)\s*=\s*"([^"]+)"', result.stdout)
    if match:
        return match.group(1)
    
    print(f"Could not find hash in output for {repo}")
    print(f"Raw output: {result.stdout}")
    return None

def main():
    parser = argparse.ArgumentParser(description="Manage Docker images for Nix")
    parser.add_argument("--update", action="store_true", help="Force check for updates on existing images")
    args = parser.parse_args()
    
    if os.path.exists(LOCK_FILE):
        with open(LOCK_FILE, "r") as f:
            lock_data = json.load(f)
    else:
        lock_data = {}

    updated_data = {}
    
    for img in IMAGES:
        name = img['name']
        repo = img['repo']
        tag = img['tag']

        if not args.update and name in lock_data:
            print(f"Skipping {name} (already in lock file)")
            updated_data[name] = lock_data[name]
            continue

        print(f"Checking {repo}:{tag}...")
        current_digest = get_remote_digest(repo, tag)
        
        if not current_digest:
            if name in lock_data:
                print(f" -> Warning: Fetch failed, keeping old data for {name}")
                updated_data[name] = lock_data[name]
            continue

        if lock_data.get(name, {}).get("imageDigest") != current_digest:
            print(f" -> New digest found: {current_digest}")
            nix_hash = prefetch_nix_hash(repo, current_digest)
            
            updated_data[name] = {
                "imageName": repo,
                "imageDigest": current_digest,
                "sha256": nix_hash
            }
        else:
            print(f" -> {name} is up to date")
            updated_data[name] = lock_data[name]

    # write lockfile and nix file
    with open(LOCK_FILE, "w") as f:
        json.dump(updated_data, f, indent=2)

    with open(NIX_FILE, "w") as f:
        f.write("{\n")
        for name, data in updated_data.items():
            f.write(f"  {name} = {{\n")
            f.write(f"    imageName = \"{data['imageName']}\";\n")
            f.write(f"    imageDigest = \"{data['imageDigest']}\";\n")
            f.write(f"    sha256 = \"{data['sha256']}\";\n")
            f.write("  };\n")
        f.write("}\n")

    print(f"\nSuccessfully updated {LOCK_FILE} and {NIX_FILE}")

if __name__ == "__main__":
    main()