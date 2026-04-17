#!/usr/bin/env bash

set -e

echo "Stopping Borg service if running."
sudo systemctl stop borgbackup-job-opt-backup.service || true

echo "Wiping all Borg data, cache, and config."
sudo rm -rfv /bak/opt/*
sudo rm -rfv /bak/borg/config/*
sudo rm -rfv /bak/borg/data/*
sudo rm -rfv /bak/borg/cache/*

echo "Re-applying directory permissions via tmpfiles."
sudo systemd-tmpfiles --create

echo "Initializing fresh Borg repository."
export BORG_BASE_DIR="/bak/borg"
export BORG_CONFIG_DIR="/bak/borg/config"
export BORG_DATA_DIR="/bak/borg/data"
export BORG_CACHE_DIR="/bak/borg/cache"

sudo -E borg init --encryption=none /bak/opt

echo "Starting the NixOS backup job."
sudo systemctl start borgbackup-job-opt-backup.service