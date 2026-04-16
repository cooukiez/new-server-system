/*
  overlays/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  inputs,
  ...
}:
{
  # custom packages from package directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # see https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {

  };
  
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      localSystem = {
        system = final.stdenv.hostPlatform.system;
      };
      config.allowUnfree = true;
    };
  };
}
