import os
import re
import sys
import argparse
from pathlib import Path
import psycopg2
from git import Repo

required_vars = {
    "OPENGIST_DB_USER": "USER",
    "OPENGIST_DB_PASS_PATH": "PASSWORD_PATH", 
    "OPENGIST_DB_HOST": "HOST",
    "OPENGIST_DB_PORT": "PORT",
}

# validate environment variables
for env_key in required_vars:
    if not os.environ.get(env_key):
        print(f"Error: {env_key} environment variable is not set.")
        sys.exit(1)

# read and validate db pass secret path
secret_path_str = os.environ.get("OPENGIST_DB_PASS_PATH")
secret_path = Path(secret_path_str)

if not secret_path.is_file():
    print(f"Error: Secret file at {secret_path_str} does not exist or is not a file.")
    sys.exit(1)

try:
    # read the password and strip
    db_password = secret_path.read_text().strip()
except Exception as e:
    print(f"Error: Could not read secret file at {secret_path_str}. Details: {e}")
    sys.exit(1)

DB_CONFIG = {
    "dbname": "opengist",
    "user": os.environ.get("OPENGIST_DB_USER"),
    "password": db_password,
    "host": os.environ.get("OPENGIST_DB_HOST"),
    "port": os.environ.get("OPENGIST_DB_PORT"),
}


def sanitize_filename(name):
    """remove invalid file/folder name characters and replaces spaces"""
    if not name:
        return "unnamed_gist"
    name = name.replace(" ", "_")
    return re.sub(r'(?u)[^-\w.]', '', name).strip('_')


def get_postgres_gist_titles():
    """fetch mapping of gist hex id to clean title from postgres"""
    titles = {}
    query = "SELECT id, title FROM gist;"
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        with conn.cursor() as cur:
            cur.execute(query)
            for gist_id, title in cur.fetchall():
                titles[gist_id] = sanitize_filename(title)
        conn.close()
    except Exception as e:
        print(f"Postgres Failed: {e}")
        print("Falling back to using raw Hex IDs for naming.")

    return titles


def main():
    # setup argument parser
    parser = argparse.ArgumentParser(description="Export Opengist repositories to clean named files/folders.")
    parser.add_argument(
        "--gists-dir", 
        default="/opt/opengist/data/repos/ludwig",
        help="Path to the Opengist repositories directory (default: %(default)s)"
    )
    parser.add_argument(
        "--export-dir", 
        default="/data/gists",
        help="Path where the gists should be exported (default: %(default)s)"
    )
    
    args = parser.parse_args()
    
    gists_dir = args.gists_dir
    export_dir = args.export_dir

    # validate that the source directory exists
    if not os.path.isdir(gists_dir):
        print(f"Error: The source gists directory '{gists_dir}' does not exist.")
        sys.exit(1)

    os.makedirs(export_dir, exist_ok=True)
    gist_titles = get_postgres_gist_titles()
    
    for gist_id in os.listdir(gists_dir):
        repo_path = os.path.join(gists_dir, gist_id)
        
        if not os.path.isdir(repo_path):
            continue
            
        try:
            repo = Repo(repo_path)
            commit = repo.head.commit
            files = [obj.path for obj in commit.tree.traverse() if obj.type == 'blob']
            
            if not files:
                continue

            base_name = gist_titles.get(gist_id, f"gist_{gist_id[:7]}")

            if len(files) == 1:
                filename = files[0]
                _, ext = os.path.splitext(filename)
                
                export_filename = f"{base_name}{ext}" if ext else base_name
                export_path = os.path.join(export_dir, export_filename)
                
                if os.path.exists(export_path):
                    export_path = os.path.join(export_dir, f"{gist_id[:7]}_{export_filename}")

                with open(export_path, "wb") as f:
                    f.write(commit.tree[filename].data_stream.read())
                print(f"Exported file: {os.path.basename(export_path)}")

            else:
                gist_export_folder = os.path.join(export_dir, base_name)
                
                if os.path.exists(gist_export_folder):
                    gist_export_folder = os.path.join(export_dir, f"{base_name}_{gist_id[:7]}")
                    
                os.makedirs(gist_export_folder, exist_ok=True)
                
                for filename in files:
                    file_export_path = os.path.join(gist_export_folder, filename)
                    os.makedirs(os.path.dirname(file_export_path), exist_ok=True)
                    
                    with open(file_export_path, "wb") as f:
                        f.write(commit.tree[filename].data_stream.read())
                        
                print(f"Exported folder: {os.path.basename(gist_export_folder)}/ ({len(files)} files)")

        except Exception as e:
            print(f"Failed processing repo {gist_id}: {e}")


if __name__ == "__main__":
    main()