import argparse
import os
import sys
from pathlib import Path
import psycopg2

REQUIRED_VARS = {
    "MAIL_ARCHIVER_DB_USER": "USER",
    "MAIL_ARCHIVER_DB_PASS_PATH": "PASSWORD_PATH",
    "MAIL_ARCHIVER_DB_HOST": "HOST",
    "MAIL_ARCHIVER_DB_PORT": "PORT",
    "MAIL_ARCHIVER_DB_NAME": "DBNAME",
}

# extensible filter rules
FILTER_RULES = [
    {
        "name": "ReDI DKP Invitations",
        "conditions": {
            "From": {"operator": "exact", "value": "kids@redi-school.org"},
            "Subject": {"operator": "like", "value": "Invitation: %"},
        },
    }
]


def validate_environment() -> dict:
    """validate env variables and read database password"""

    missing = [var for var in REQUIRED_VARS if not os.environ.get(var)]
    if missing:
        print(
            f"Error: Missing environment variables: {', '.join(missing)}",
            file=sys.stderr,
        )
        sys.exit(1)

    secret_path = Path(os.environ["MAIL_ARCHIVER_DB_PASS_PATH"])
    if not secret_path.is_file():
        print(f"Error: Secret file at {secret_path} does not exist.", file=sys.stderr)
        sys.exit(1)

    try:
        return {
            "dbname": os.environ.get("MAIL_ARCHIVER_DB_NAME"),
            "user": os.environ.get("MAIL_ARCHIVER_DB_USER"),
            "password": secret_path.read_text().strip(),
            "host": os.environ.get("MAIL_ARCHIVER_DB_HOST"),
            "port": os.environ.get("MAIL_ARCHIVER_DB_PORT"),
        }
    except Exception as e:
        print(f"Error reading secret file: {e}", file=sys.stderr)
        sys.exit(1)


def build_query_and_params(conditions: dict) -> tuple:
    """dynamically build where clause based on rule conditions"""

    where_clauses = []
    params = []

    for column, lookup in conditions.items():
        operator = lookup["operator"].lower()
        value = lookup["value"]

        if operator == "exact":
            where_clauses.append(f'"{column}" = %s')
            params.append(value)
        elif operator == "like":
            where_clauses.append(f'"{column}" LIKE %s')
            params.append(value)
        else:
            raise ValueError(f"Unsupported operator: {operator}")

    query = f'SELECT "Id" FROM "Emails" WHERE {" AND ".join(where_clauses)};'
    return query, tuple(params)


def parse_arguments():
    """parse command line arguments"""

    parser = argparse.ArgumentParser(
        description="Mail archiver cleanup maintenance script."
    )
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="Simulate the cleanup process and display counts without modifying the database.",
    )
    return parser.parse_args()


def get_targeted_email_ids(cursor) -> list:
    """evaluate filter rules and collect unique email ids"""

    all_email_ids = set()

    for rule in FILTER_RULES:
        print(f"Processing rule: {rule['name']}...")
        query, params = build_query_and_params(rule["conditions"])

        cursor.execute(query, params)
        ids = [row[0] for row in cursor.fetchall()]

        if ids:
            print(f"  -> Found {len(ids)} matching emails.")
            all_email_ids.update(ids)
        else:
            print("  -> No matches found.")

    return list(all_email_ids)


def run_dry_run(cursor, target_ids: list):
    """simulate deletion and calculate the impact"""

    query = 'SELECT COUNT(*) FROM "Attachments" WHERE "ArchivedEmailId" = ANY(%s);'
    cursor.execute(query, (target_ids,))
    attachments_count = cursor.fetchone()[0]

    print("\n--- DRY RUN RESULTS ---")
    print(f"Emails that would be deleted: {len(target_ids)}")
    print(f"Attachments that would be deleted: {attachments_count}")
    print("-----------------------")
    print("No database modifications made.")


def execute_cleanup(cursor, target_ids: list):
    """execute the actual deletion inside the transaction block"""

    """

    # delete attachments first due to foreign key constraints
    del_attachments_query = (
        'DELETE FROM "Attachments" WHERE "ArchivedEmailId" = ANY(%s);'
    )

    cursor.execute(del_attachments_query, (target_ids,))
    print(f"Deleted {cursor.rowcount} associated attachment(s).")

    # delete emails
    del_emails_query = 'DELETE FROM "Emails" WHERE "Id" = ANY(%s);'
    cursor.execute(del_emails_query, (target_ids,))
    print(f"Deleted {cursor.rowcount} email record(s).")

    """


def main():
    args = parse_arguments()
    db_config = validate_environment()

    if args.dry_run:
        print("RUNNING IN DRY-RUN MODE: No changes will be saved.\n")

    try:
        # using context managers auto-closes connections / cursors and manages transactions
        with psycopg2.connect(**db_config) as conn:
            with conn.cursor() as cursor:
                target_ids = get_targeted_email_ids(cursor)

                if not target_ids:
                    print("\nNo matching records found across all rules.")
                    return

                print(f"\nTotal unique emails target matched: {len(target_ids)}")

                if args.dry_run:
                    run_dry_run(cursor, target_ids)
                else:
                    execute_cleanup(cursor, target_ids)
                    print("Cleanup transaction successfully completed.")

    except Exception as e:
        print(f"Database error occurred: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
