/*
  modules/nixos/common/default.nix

  part of der-home-server
  created 2026-04-08
*/

{
  inputs,
  pkgs,
  lib,
  hostSystem,
  ...
}:
{
  imports = [
    ./tools.nix
  ];

  services.dbus.enable = true;
  services.fwupd.enable = true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    GIT_SSH_COMMAND = "ssh -i /home/admin/.ssh/id_ed25519";
  };

  environment.localBinInPath = true;
  environment.enableAllTerminfo = true;

  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
  };

  programs.zsh.enable = true;

  # system packages
  environment.systemPackages = with pkgs; [
    # core packages, sorted alphabetically
    age
    cifs-utils
    coreutils
    cpuid
    curl
    diffutils
    dmidecode
    exfatprogs
    exiftool
    fastfetch
    fdupes
    fzf
    git
    gnumake
    gnutar
    inetutils
    jq
    killall
    lsof
    mesa
    mtools
    ntfsprogs
    openssl
    parted
    rclone
    rsync
    rustup
    sd
    tmux
    toybox
    tree
    unixtools.quota
    unzip
    wget
    zip

    # encryption
    inputs.agenix.packages.${hostSystem}.default

    # nixos related
    home-manager
    nixfmt-rfc-style
    nixfmt-tree
    nix-prefetch-git
    nix-search
  ];
}
