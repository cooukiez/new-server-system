/*
overlays/default.nix

part of server system
created 2026-05-13 by ludw
*/
{
  inputs,
  system,
  ...
}: {
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: {
    agenix = inputs.agenix.packages.${system}.default;
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
