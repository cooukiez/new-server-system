/*
  overlays/default.nix

  part of der-home-server
  created 2026-04-16
*/

{
  inputs,
  ...
}:
{
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: { };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      localSystem = {
        system = final.stdenv.hostPlatform.system;
      };
      config.allowUnfree = true;
    };
  };
}
