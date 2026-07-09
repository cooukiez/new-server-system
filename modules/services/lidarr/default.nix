/*
modules/services/lidarr/default.nix

part of server system
created 2026-07-09 by ludw
*/
{pkgs, ...}: let
  opus-transcoder = pkgs.writers.writePython3Bin "opus-transcoder" {
    makeWrapperArgs = ["--prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ffmpeg]}"];
  } (builtins.readFile ./transcoder.py);
in {
  environment.systemPackages = [
    opus-transcoder
  ];
}
