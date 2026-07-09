import argparse
import os
import re
import shutil
import sys
from pathlib import Path
from git import Repo
import psycopg2

REQUIRED_VARS = {
    "OPENGIST_DB_USER": "USER",
    "OPENGIST_DB_PASS_PATH": "PASSWORD_PATH",
    "OPENGIST_DB_HOST": "HOST",
    "OPENGIST_DB_PORT": "PORT",
}


def validate_environment() -> dict:
    """validate env variables and read database password"""

    missing = [var for var in REQUIRED_VARS if not os.environ.get(var)]
    if missing:
        print(
            f"Error: Missing environment variables: {', '.join(missing)}",
            file=sys.stderr,
        )

        sys.exit(1)

    secret_path = Path(os.environ["OPENGIST_DB_PASS_PATH"])
    if not secret_path.is_file():
        print(
            f"Error: Secret file at {secret_path} does not exist.",
            file=sys.stderr,
        )

        sys.exit(1)

    try:
        return {
            "dbname": "opengist",
            "user": os.environ.get("OPENGIST_DB_USER"),
            "password": secret_path.read_text().strip(),
            "host": os.environ.get("OPENGIST_DB_HOST"),
            "port": os.environ.get("OPENGIST_DB_PORT"),
        }

    except Exception as e:
        print(f"Error reading secret file: {e}", file=sys.stderr)
        sys.exit(1)


def sanitize_filename(name: str) -> str:
    """remove invalid file / folder name characters and replace spaces"""

    if not name:
        return "unnamed_gist"

    name = name.replace(" ", "_")
    return re.sub(r"(?u)[^-\w.]", "", name).strip("_")


def get_postgres_gist_titles(db_config: dict) -> dict:
    """fetch mapping of gist hex uuid to clean title from postgres"""

    titles = {}
    query = "SELECT uuid, title FROM gists;"

    try:
        with psycopg2.connect(**db_config) as conn:
            with conn.cursor() as cur:
                cur.execute(query)
                for gist_id, title in cur.fetchall():
                    titles[str(gist_id)] = sanitize_filename(title)
    except Exception as e:
        print(
            f"Postgres Connection Failed: {e}. Falling back to raw Hex IDs.",
            file=sys.stderr,
        )

    return titles


def export_gist(repo_path: Path, export_dir: Path, gist_titles: dict):
    """process and export a single git repository mapping"""

    gist_id = repo_path.name

    try:
        repo = Repo(repo_path)
        commit = repo.head.commit
        files = [
            obj.path for obj in commit.tree.traverse() if obj.type == "blob"
        ]

        if not files:
            return

        base_name = gist_titles.get(gist_id, f"gist_{gist_id[:7]}")

        # single file gist
        if len(files) == 1:
            filename = files[0]
            export_path = export_dir / filename

            if export_path.exists():
                export_path = export_dir / f"{gist_id[:7]}_{filename}"

            with open(export_path, "wb") as f_out:
                shutil.copyfileobj(commit.tree[filename].data_stream, f_out)

            print(f"Exported file: {export_path.name}")

        # multi-file gist (folder structure)
        else:
            gist_export_folder = export_dir / base_name
            if gist_export_folder.exists():
                gist_export_folder = export_dir / f"{base_name}_{gist_id[:7]}"

            gist_export_folder.mkdir(parents=True, exist_ok=True)

            for filename in files:
                file_export_path = gist_export_folder / filename
                file_export_path.parent.mkdir(parents=True, exist_ok=True)

                with open(file_export_path, "wb") as f_out:
                    shutil.copyfileobj(
                        commit.tree[filename].data_stream, f_out
                    )

            print(
                f"Exported folder: {gist_export_folder.name}/ ({len(files)} files)"
            )

    except Exception as e:
        print(f"Failed processing repo {gist_id}: {e}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Export Opengist repositories to clean named files/folders."
    )

    parser.add_argument(
        "--gists-dir",
        default="/opt/opengist/data/repos/ludwig",
        help="Path to the Opengist repositories directory",
    )

    parser.add_argument(
        "--export-dir",
        default="/data/gists",
        help="Path where the gists should be exported",
    )

    args = parser.parse_args()

    gists_dir = Path(args.gists_dir)
    export_dir = Path(args.export_dir)

    if not gists_dir.is_dir():
        print(
            f"Error: Source directory '{gists_dir}' does not exist.",
            file=sys.stderr,
        )
        
        sys.exit(1)

    export_dir.mkdir(parents=True, exist_ok=True)

    db_config = validate_environment()
    gist_titles = get_postgres_gist_titles(db_config)

    for repo_path in gists_dir.iterdir():
        if repo_path.is_dir():
            export_gist(repo_path, export_dir, gist_titles)


if __name__ == "__main__":
    main()
