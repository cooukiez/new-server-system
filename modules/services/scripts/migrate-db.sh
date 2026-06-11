#!/usr/bin/env bash

# exit on error
set -e

echo "========================================="
echo "   Podman PostgreSQL Migration Script"
echo "========================================="
echo ""

read -p "Source Container Name [postgres]: " SRC_CONTAINER
SRC_CONTAINER=${SRC_CONTAINER:-postgres}

read -p "Source DB User [admin]: " DB_USER
DB_USER=${DB_USER:-admin}

read -p "Source DB Name [database]: " DB_NAME
DB_NAME=${DB_NAME:-database}

read -p "Target Container Name [service-postgres]: " TARGET_CONTAINER
TARGET_CONTAINER=${TARGET_CONTAINER:-service-postgres}

read -p "Target DB Name [$DB_NAME]: " TARGET_DB_NAME
TARGET_DB_NAME=${TARGET_DB_NAME:-$DB_NAME}

LOCAL_DUMP_PATH="/tmp/database.dump"

echo ""
echo "-----------------------------------------"
echo "Configuration Summary:"
echo "Source Container: $SRC_CONTAINER"
echo "Source DB User:   $DB_USER"
echo "Source DB Name:   $DB_NAME"
echo "Target Container: $TARGET_CONTAINER"
echo "Target DB Name:   $TARGET_DB_NAME"
echo "Local Dump Path:  $LOCAL_DUMP_PATH"
echo "-----------------------------------------"
read -p "Is this information correct? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Migration aborted by user."
    exit 1
fi

echo ""
echo "=> Starting database container..."
systemctl --user start "$TARGET_CONTAINER"

echo ""
echo "=> Exporting database from source container ($SRC_CONTAINER)..."
podman exec -t "$SRC_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c -b -v -f /tmp/database.dump

echo "=> Copying dump file from source container to local machine..."
podman cp "$SRC_CONTAINER":/tmp/database.dump "$LOCAL_DUMP_PATH"

echo "=> Copying dump file from local machine to target container ($TARGET_CONTAINER)..."
podman cp "$LOCAL_DUMP_PATH" "$TARGET_CONTAINER":/tmp/database.dump

echo ""
echo "=> Preparing target database (dropping if exists and recreating)..."

podman exec "$TARGET_CONTAINER" psql -U "$DB_USER" -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TARGET_DB_NAME' AND pid <> pg_backend_pid();"

podman exec "$TARGET_CONTAINER" dropdb -U "$DB_USER" --if-exists "$TARGET_DB_NAME"

podman exec "$TARGET_CONTAINER" createdb -U "$DB_USER" "$TARGET_DB_NAME"

echo "=> Restoring database in target container..."
podman exec -t "$TARGET_CONTAINER" pg_restore -U "$DB_USER" -d "$TARGET_DB_NAME" --no-owner --no-acl -v /tmp/database.dump
echo ""
echo "========================================="
echo "      Database migration completed!"
echo "========================================="

# optional cleanup
read -p "Would you like to delete the local dump file ($LOCAL_DUMP_PATH)? (y/N): " CLEANUP
if [[ "$CLEANUP" =~ ^[Yy]$ ]]; then
    rm -f "$LOCAL_DUMP_PATH"
    echo "Local dump file removed."
fi