/*
  modules/containers/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  config,
  ...
}:
let
  ports = {
    grafana = 3000;
  };
{
  imports = [
    ./services/immich.nix
    
    ./auth.nix
    ./database.nix
    ./dns.nix
    ./monitor.nix
    ./reverse-proxy.nix
    ./users.nix
  ];

  _module.args = { inherit ports; };

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
