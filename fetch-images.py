import subprocess
import json
import os
import re

IMAGES = [
    {"name": "authelia", "repo": "ghcr.io/authelia/authelia", "tag": "latest"},
    {"name": "postgres", "repo": "docker.io/library/postgres", "tag": "alpine"},
    {"name": "adguard", "repo": "docker.io/adguard/adguardhome", "tag": "latest"},
    {"name": "homepage", "repo": "ghcr.io/gethomepage/homepage", "tag": "latest"},
    {"name": "gluetun", "repo": "ghcr.io/qdm12/gluetun", "tag": "latest"},
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
    if os.path.exists(LOCK_FILE):
        with open(LOCK_FILE, "r") as f:
            lock_data = json.load(f)
    else:
        lock_data = {}

    updated_data = {}
    
    for img in IMAGES:
        print(f"Checking {img['repo']}:{img['tag']}")

        current_digest = get_remote_digest(img['repo'], img['tag'])
        
        if not current_digest:
            continue

        # check if digest changed or entry is new
        if lock_data.get(img['name'], {}).get("imageDigest") != current_digest:
            print(f" -> New digest: {current_digest}")

            nix_hash = prefetch_nix_hash(img['repo'], current_digest)
            updated_data[img['name']] = {
                "imageName": img['repo'],
                "imageDigest": current_digest,
                "sha256": nix_hash
            }
        else:
            print(" -> Up to date")
            updated_data[img['name']] = lock_data[img['name']]

    # write lockfile and nix file
    with open(LOCK_FILE, "w") as f:
        json.dump(updated_data, f, indent=2)

    with open(NIX_FILE, "w") as f:
        f.write("# this file is generated automatically\n{\n")
        for name, data in updated_data.items():
            f.write(f"  {name} = {{\n")
            f.write(f"    imageName = \"{data['imageName']}\";\n")
            f.write(f"    imageDigest = \"{data['imageDigest']}\";\n")
            f.write(f"    sha256 = \"{data['sha256']}\";\n")
            f.write("  };\n")
        f.write("}\n")

    print(f"\nUpdated {LOCK_FILE} and {NIX_FILE}")

if __name__ == "__main__":
    main()