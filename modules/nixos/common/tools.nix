/*
  modules/nixos/common/tools.nix

  part of der-home-server
  created 2026-03-18
*/

{
  pkgs,
  ...
}:
let
  clear-logs = pkgs.writeShellScriptBin "clear-logs" (builtins.readFile ./scripts/clear-logs.sh);
  fix-perms = pkgs.writeShellScriptBin "fix-perms" (builtins.readFile ./scripts/fix-perms.sh);
  sync-flake = pkgs.writeShellScriptBin "sync-flake" (builtins.readFile ./scripts/sync-flake.sh);
in
{
  # nvim base editor
  programs.neovim.enable = true;

  environment.systemPackages = with pkgs; [
    # cli tools, sorted alphabetically
    aria2
    bench
    btop
    ctop
    dfc
    dig
    dua
    gping
    htop
    httpie
    # ngrok
    nssTools
    powertop
    procs
    ripgrep

    # my scripts
    clear-logs
    fix-perms
    sync-flake

    # tools
    intel-gpu-tools
    nvtopPackages.intel
  ];
}
