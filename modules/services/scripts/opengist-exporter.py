import os
import re
import sys
import psycopg2
from git import Repo

required_vars = {
    "OPENGIST_DB_USER": "USER",
    "OPENGIST_DB_PASS": "PASSWORD",
    "OPENGIST_DB_HOST": "HOST",
    "OPENGIST_DB_PORT": "PORT",
}

for env_key in required_vars:
    if not os.environ.get(env_key):
        print(f"Error: {env_key} environment variable is not set.")
        sys.exit(1)

DB_CONFIG = {
    "dbname": "opengist",
    "user": os.environ.get("OPENGIST_DB_USER"),
    "password": os.environ.get("OPENGIST_DB_PASS"),
    "host": os.environ.get("OPENGIST_DB_HOST"),
    "port": os.environ.get("OPENGIST_DB_PORT"),
}

OPENGIST_GISTS_DIR = "/opt/opengist/data/repos/ludwig"
EXPORT_DIR = "/data/opengist"

def sanitize_filename(name):
    """remove invalid file/folder name characters and replaces spaces"""
    if not name:
        return "unnamed_gist"
    name = name.replace(" ", "_")
    return re.sub(r'(?u)[^-\w.]', '', name).strip('_')

def get_postgres_gist_titles():
    """fetch mapping of gist hex id -> clean title from postgres"""
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
    os.makedirs(EXPORT_DIR, exist_ok=True)
    gist_titles = get_postgres_gist_titles()
    
    for gist_id in os.listdir(OPENGIST_GISTS_DIR):
        repo_path = os.path.join(OPENGIST_GISTS_DIR, gist_id)
        
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
                export_path = os.path.join(EXPORT_DIR, export_filename)
                
                if os.path.exists(export_path):
                    export_path = os.path.join(EXPORT_DIR, f"{gist_id[:7]}_{export_filename}")

                with open(export_path, "wb") as f:
                    f.write(commit.tree[filename].data_stream.read())
                print(f"Exported file: {os.path.basename(export_path)}")

            else:
                gist_export_folder = os.path.join(EXPORT_DIR, base_name)
                
                if os.path.exists(gist_export_folder):
                    gist_export_folder = os.path.join(EXPORT_DIR, f"{base_name}_{gist_id[:7]}")
                    
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