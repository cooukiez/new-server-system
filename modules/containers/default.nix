/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  config,
  ...
}:
{
  imports = [
    ./auth.nix
    ./database.nix
    ./dns.nix
    ./reverse-proxy.nix
  ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks = {
        internal.networkConfig.subnets = [ "10.1.1.1/24" ];
      };
    };
}
