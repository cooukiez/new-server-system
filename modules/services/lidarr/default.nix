/*
modules/services/lidarr/default.nix

part of server system
created 2026-07-09 by ludw
*/
{pkgs, ...}: let
  opus-transcode = pkgs.writers.writePython3Bin "opus-transcode" {
    makeWrapperArgs = ["--prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ffmpeg]}"];
  } (builtins.readFile ./transcode.py);
in {
  environment.systemPackages = [
    opus-transcode
  ];
}
